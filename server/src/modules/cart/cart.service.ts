import { Prisma } from "@prisma/client";
import { prisma } from "../../config/prisma";
import { BadRequestError, NotFoundError } from "../../common/errors/AppError";
import type { AddCartItemInput, UpdateCartItemInput } from "./cart.schema";

const cartInclude = {
  items: {
    include: {
      product: {
        include: { images: { orderBy: { sortOrder: "asc" as const }, take: 1 } },
      },
    },
  },
};

// userId에 유니크 제약이 걸려 있어, 같은 사용자의 요청 두 개가 동시에 들어오면
// upsert끼리 경합하다 한쪽이 P2002(유니크 제약 위반)로 실패할 수 있다.
// 이 경우는 이미 다른 요청이 카트를 만들어준 것이므로 재조회로 복구한다.
async function getOrCreateCart(userId: string) {
  try {
    return await prisma.cart.upsert({
      where: { userId },
      update: {},
      create: { userId },
    });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      return prisma.cart.findUniqueOrThrow({ where: { userId } });
    }
    throw err;
  }
}

export async function getCart(userId: string) {
  const cart = await getOrCreateCart(userId);
  return prisma.cart.findUniqueOrThrow({
    where: { id: cart.id },
    include: cartInclude,
  });
}

export async function addItem(userId: string, input: AddCartItemInput) {
  const product = await prisma.product.findUnique({ where: { id: input.productId } });
  if (!product || !product.isActive) {
    throw new NotFoundError("상품을 찾을 수 없습니다.");
  }

  const cart = await getOrCreateCart(userId);
  const existing = await prisma.cartItem.findUnique({
    where: { cartId_productId: { cartId: cart.id, productId: input.productId } },
  });

  const nextQuantity = (existing?.quantity ?? 0) + input.quantity;
  if (nextQuantity > product.stock) {
    throw new BadRequestError(`재고가 부족합니다. (재고 ${product.stock}개)`);
  }

  await prisma.cartItem.upsert({
    where: { cartId_productId: { cartId: cart.id, productId: input.productId } },
    update: { quantity: nextQuantity },
    create: { cartId: cart.id, productId: input.productId, quantity: nextQuantity },
  });

  return getCart(userId);
}

export async function updateItem(userId: string, productId: string, input: UpdateCartItemInput) {
  const cart = await getOrCreateCart(userId);
  const item = await prisma.cartItem.findUnique({
    where: { cartId_productId: { cartId: cart.id, productId } },
    include: { product: true },
  });
  if (!item) {
    throw new NotFoundError("장바구니에 없는 상품입니다.");
  }
  if (input.quantity > item.product.stock) {
    throw new BadRequestError(`재고가 부족합니다. (재고 ${item.product.stock}개)`);
  }

  await prisma.cartItem.update({ where: { id: item.id }, data: { quantity: input.quantity } });
  return getCart(userId);
}

export async function removeItem(userId: string, productId: string) {
  const cart = await getOrCreateCart(userId);
  await prisma.cartItem.deleteMany({ where: { cartId: cart.id, productId } });
  return getCart(userId);
}
