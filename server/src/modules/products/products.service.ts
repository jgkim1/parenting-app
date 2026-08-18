import { Prisma } from "@prisma/client";
import { prisma } from "../../config/prisma";
import { ConflictError, ForbiddenError, NotFoundError } from "../../common/errors/AppError";
import type {
  CreateProductInput,
  CreateReviewInput,
  ListProductsQuery,
  UpdateProductInput,
  UpdateReviewInput,
} from "./products.schema";

export async function listCategories() {
  return prisma.category.findMany({
    orderBy: { name: "asc" },
  });
}

const productListInclude = {
  images: { orderBy: { sortOrder: "asc" as const }, take: 1 },
  category: { select: { id: true, name: true, slug: true } },
} satisfies Prisma.ProductInclude;

// includeInactive는 관리자 상품 관리 화면에서만 true로 전달된다(컨트롤러에서 role 검증).
export async function listProducts(query: ListProductsQuery, includeInactive = false) {
  const where: Prisma.ProductWhereInput = {
    ...(includeInactive ? {} : { isActive: true }),
    ...(query.categoryId ? { categoryId: query.categoryId } : {}),
    ...(query.q ? { name: { contains: query.q, mode: "insensitive" } } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where,
      include: productListInclude,
      orderBy: { createdAt: "desc" },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    prisma.product.count({ where }),
  ]);

  return {
    items,
    page: query.page,
    pageSize: query.pageSize,
    total,
    totalPages: Math.max(1, Math.ceil(total / query.pageSize)),
  };
}

export async function getProductById(id: string, includeInactive = false) {
  const product = await prisma.product.findUnique({
    where: { id },
    include: {
      images: { orderBy: { sortOrder: "asc" } },
      category: { select: { id: true, name: true, slug: true } },
      seller: { select: { id: true, nickname: true } },
      reviews: {
        orderBy: { createdAt: "desc" },
        take: 20,
        include: { user: { select: { id: true, nickname: true } } },
      },
    },
  });

  if (!product || (!product.isActive && !includeInactive)) {
    throw new NotFoundError("상품을 찾을 수 없습니다.");
  }

  const reviewStats = await prisma.review.aggregate({
    where: { productId: id },
    _avg: { rating: true },
    _count: true,
  });

  return {
    ...product,
    reviewStats: {
      average: reviewStats._avg.rating ?? 0,
      count: reviewStats._count,
    },
  };
}

export async function createReview(userId: string, productId: string, input: CreateReviewInput) {
  const product = await prisma.product.findUnique({ where: { id: productId } });
  if (!product || !product.isActive) {
    throw new NotFoundError("상품을 찾을 수 없습니다.");
  }

  try {
    return await prisma.review.create({
      data: { productId, userId, rating: input.rating, content: input.content },
      include: { user: { select: { id: true, nickname: true } } },
    });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      throw new ConflictError("이미 이 상품에 리뷰를 작성하셨습니다.");
    }
    throw err;
  }
}

export async function updateReview(userId: string, reviewId: string, input: UpdateReviewInput) {
  const review = await prisma.review.findUnique({ where: { id: reviewId } });
  if (!review) {
    throw new NotFoundError("리뷰를 찾을 수 없습니다.");
  }
  if (review.userId !== userId) {
    throw new ForbiddenError("본인 리뷰만 수정할 수 있습니다.");
  }

  return prisma.review.update({
    where: { id: reviewId },
    data: { rating: input.rating, content: input.content },
    include: { user: { select: { id: true, nickname: true } } },
  });
}

export async function deleteReview(userId: string, reviewId: string) {
  const review = await prisma.review.findUnique({ where: { id: reviewId } });
  if (!review) {
    throw new NotFoundError("리뷰를 찾을 수 없습니다.");
  }
  if (review.userId !== userId) {
    throw new ForbiddenError("본인 리뷰만 삭제할 수 있습니다.");
  }
  await prisma.review.delete({ where: { id: reviewId } });
}

export async function createProduct(sellerId: string, input: CreateProductInput) {
  const category = await prisma.category.findUnique({ where: { id: input.categoryId } });
  if (!category) {
    throw new NotFoundError("카테고리를 찾을 수 없습니다.");
  }

  return prisma.product.create({
    data: {
      sellerId,
      categoryId: input.categoryId,
      name: input.name,
      description: input.description,
      price: input.price,
      stock: input.stock,
      images: {
        create: input.imageUrls.map((url, index) => ({ url, sortOrder: index })),
      },
    },
    include: productListInclude,
  });
}

// ADMIN은 모든 상품을, SELLER는 본인이 등록한 상품만 수정할 수 있다.
export async function updateProduct(
  requesterId: string,
  requesterRole: string,
  productId: string,
  input: UpdateProductInput,
) {
  const product = await prisma.product.findUnique({ where: { id: productId } });
  if (!product) {
    throw new NotFoundError("상품을 찾을 수 없습니다.");
  }
  if (requesterRole !== "ADMIN" && product.sellerId !== requesterId) {
    throw new ForbiddenError("본인이 등록한 상품만 수정할 수 있습니다.");
  }

  if (input.categoryId) {
    const category = await prisma.category.findUnique({ where: { id: input.categoryId } });
    if (!category) {
      throw new NotFoundError("카테고리를 찾을 수 없습니다.");
    }
  }

  return prisma.product.update({
    where: { id: productId },
    data: {
      categoryId: input.categoryId,
      name: input.name,
      description: input.description,
      price: input.price,
      stock: input.stock,
      isActive: input.isActive,
      ...(input.imageUrls
        ? {
            images: {
              deleteMany: {},
              create: input.imageUrls.map((url, index) => ({ url, sortOrder: index })),
            },
          }
        : {}),
    },
    include: productListInclude,
  });
}
