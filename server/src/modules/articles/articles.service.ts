import type { Prisma } from "@prisma/client";
import { prisma } from "../../config/prisma";
import { NotFoundError } from "../../common/errors/AppError";
import type { CreateArticleInput, ListArticlesQuery, UpdateArticleInput } from "./articles.schema";

export async function listArticleCategories() {
  return prisma.articleCategory.findMany({
    orderBy: { name: "asc" },
  });
}

const articleListInclude = {
  category: { select: { id: true, name: true, slug: true } },
} satisfies Prisma.ArticleInclude;

// includeInactive는 관리자 육아정보 관리 화면에서만 true로 전달된다(컨트롤러에서 role 검증).
export async function listArticles(query: ListArticlesQuery, includeInactive = false) {
  const where: Prisma.ArticleWhereInput = {
    ...(includeInactive ? {} : { isActive: true }),
    ...(query.categoryId ? { categoryId: query.categoryId } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.article.findMany({
      where,
      include: articleListInclude,
      orderBy: { createdAt: "desc" },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    prisma.article.count({ where }),
  ]);

  return {
    items,
    page: query.page,
    pageSize: query.pageSize,
    total,
    totalPages: Math.max(1, Math.ceil(total / query.pageSize)),
  };
}

export async function getArticleById(id: string, includeInactive = false) {
  const article = await prisma.article.findUnique({
    where: { id },
    include: {
      category: { select: { id: true, name: true, slug: true } },
      author: { select: { id: true, nickname: true } },
    },
  });

  if (!article || (!article.isActive && !includeInactive)) {
    throw new NotFoundError("아티클을 찾을 수 없습니다.");
  }

  // 관리자가 관리 화면에서 미리보기하는 경우(비공개 글 포함 조회)는 조회수를 올리지 않는다.
  if (!includeInactive) {
    await prisma.article.update({
      where: { id },
      data: { viewCount: { increment: 1 } },
    });
    article.viewCount += 1;
  }

  return article;
}

export async function createArticle(authorId: string, input: CreateArticleInput) {
  const category = await prisma.articleCategory.findUnique({ where: { id: input.categoryId } });
  if (!category) {
    throw new NotFoundError("카테고리를 찾을 수 없습니다.");
  }

  return prisma.article.create({
    data: {
      authorId,
      categoryId: input.categoryId,
      title: input.title,
      content: input.content,
      thumbnailUrl: input.thumbnailUrl,
    },
    include: articleListInclude,
  });
}

export async function updateArticle(id: string, input: UpdateArticleInput) {
  const article = await prisma.article.findUnique({ where: { id } });
  if (!article) {
    throw new NotFoundError("아티클을 찾을 수 없습니다.");
  }

  if (input.categoryId) {
    const category = await prisma.articleCategory.findUnique({ where: { id: input.categoryId } });
    if (!category) {
      throw new NotFoundError("카테고리를 찾을 수 없습니다.");
    }
  }

  return prisma.article.update({
    where: { id },
    data: {
      categoryId: input.categoryId,
      title: input.title,
      content: input.content,
      thumbnailUrl: input.thumbnailUrl,
      isActive: input.isActive,
    },
    include: articleListInclude,
  });
}

// 아티클은 주문/리뷰처럼 이력 보존이 필요한 다른 데이터가 참조하지 않아 하드 삭제한다.
export async function deleteArticle(id: string) {
  const article = await prisma.article.findUnique({ where: { id } });
  if (!article) {
    throw new NotFoundError("아티클을 찾을 수 없습니다.");
  }
  await prisma.article.delete({ where: { id } });
}
