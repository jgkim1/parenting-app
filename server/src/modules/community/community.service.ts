import { Prisma } from "@prisma/client";
import { prisma } from "../../config/prisma";
import { ForbiddenError, NotFoundError } from "../../common/errors/AppError";
import type {
  CreateCommentInput,
  CreatePostInput,
  ListPostsQuery,
  UpdatePostInput,
} from "./community.schema";

const postListSelect = {
  id: true,
  title: true,
  category: true,
  imageUrl: true,
  viewCount: true,
  createdAt: true,
  author: { select: { id: true, nickname: true } },
  _count: { select: { comments: true, likes: true } },
} satisfies Prisma.PostSelect;

export async function listPosts(query: ListPostsQuery) {
  const where: Prisma.PostWhereInput = {
    ...(query.category ? { category: query.category } : {}),
    ...(query.q
      ? {
          OR: [
            { title: { contains: query.q, mode: "insensitive" } },
            { content: { contains: query.q, mode: "insensitive" } },
          ],
        }
      : {}),
  };

  const [items, total] = await Promise.all([
    prisma.post.findMany({
      where,
      select: postListSelect,
      orderBy: { createdAt: "desc" },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    prisma.post.count({ where }),
  ]);

  return {
    items,
    page: query.page,
    pageSize: query.pageSize,
    total,
    totalPages: Math.max(1, Math.ceil(total / query.pageSize)),
  };
}

// currentUserId가 없으면(비로그인) likes 필터가 빈 문자열로 걸려 항상 0건이 되므로
// include 형태를 그대로 유지하면서 자연스럽게 likedByMe=false가 된다.
export async function getPostById(id: string, currentUserId?: string) {
  const post = await prisma.post.findUnique({
    where: { id },
    include: {
      author: { select: { id: true, nickname: true } },
      comments: {
        orderBy: { createdAt: "asc" },
        take: 50,
        include: { author: { select: { id: true, nickname: true } } },
      },
      likes: { where: { userId: currentUserId ?? "" }, select: { id: true } },
      _count: { select: { likes: true } },
    },
  });

  if (!post) {
    throw new NotFoundError("게시글을 찾을 수 없습니다.");
  }

  await prisma.post.update({ where: { id }, data: { viewCount: { increment: 1 } } });

  const { likes, _count, viewCount, ...rest } = post;
  return {
    ...rest,
    viewCount: viewCount + 1,
    likeCount: _count.likes,
    likedByMe: likes.length > 0,
  };
}

export async function createPost(authorId: string, input: CreatePostInput) {
  return prisma.post.create({
    data: {
      authorId,
      title: input.title,
      content: input.content,
      category: input.category,
      imageUrl: input.imageUrl,
    },
    include: { author: { select: { id: true, nickname: true } } },
  });
}

export async function updatePost(userId: string, postId: string, input: UpdatePostInput) {
  const post = await prisma.post.findUnique({ where: { id: postId } });
  if (!post) {
    throw new NotFoundError("게시글을 찾을 수 없습니다.");
  }
  if (post.authorId !== userId) {
    throw new ForbiddenError("본인 게시글만 수정할 수 있습니다.");
  }

  return prisma.post.update({
    where: { id: postId },
    data: {
      title: input.title,
      content: input.content,
      category: input.category,
      imageUrl: input.imageUrl,
    },
    include: { author: { select: { id: true, nickname: true } } },
  });
}

export async function deletePost(userId: string, postId: string) {
  const post = await prisma.post.findUnique({ where: { id: postId } });
  if (!post) {
    throw new NotFoundError("게시글을 찾을 수 없습니다.");
  }
  if (post.authorId !== userId) {
    throw new ForbiddenError("본인 게시글만 삭제할 수 있습니다.");
  }
  await prisma.post.delete({ where: { id: postId } });
}

export async function addComment(userId: string, postId: string, input: CreateCommentInput) {
  const post = await prisma.post.findUnique({ where: { id: postId } });
  if (!post) {
    throw new NotFoundError("게시글을 찾을 수 없습니다.");
  }

  return prisma.comment.create({
    data: { postId, authorId: userId, content: input.content },
    include: { author: { select: { id: true, nickname: true } } },
  });
}

export async function deleteComment(userId: string, commentId: string) {
  const comment = await prisma.comment.findUnique({ where: { id: commentId } });
  if (!comment) {
    throw new NotFoundError("댓글을 찾을 수 없습니다.");
  }
  if (comment.authorId !== userId) {
    throw new ForbiddenError("본인 댓글만 삭제할 수 있습니다.");
  }
  await prisma.comment.delete({ where: { id: commentId } });
}

// 좋아요 추가는 동시 클릭 시 유니크 제약(P2002) 경합이 날 수 있어, 이미 눌린 것으로
// 간주하고 무시한다. 최종 liked/likeCount는 항상 다시 조회해 반환하므로 일관성이 깨지지 않는다.
export async function toggleLike(userId: string, postId: string) {
  const post = await prisma.post.findUnique({ where: { id: postId } });
  if (!post) {
    throw new NotFoundError("게시글을 찾을 수 없습니다.");
  }

  const existing = await prisma.like.findUnique({
    where: { postId_userId: { postId, userId } },
  });

  if (existing) {
    await prisma.like.deleteMany({ where: { postId, userId } });
  } else {
    try {
      await prisma.like.create({ data: { postId, userId } });
    } catch (err) {
      if (!(err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002")) {
        throw err;
      }
    }
  }

  const [likeCount, likedByMe] = await Promise.all([
    prisma.like.count({ where: { postId } }),
    prisma.like.findUnique({ where: { postId_userId: { postId, userId } } }),
  ]);

  return { liked: Boolean(likedByMe), likeCount };
}
