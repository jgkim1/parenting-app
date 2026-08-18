import { prisma } from "../../config/prisma";
import { BadRequestError, NotFoundError } from "../../common/errors/AppError";
import type { CreateOrderInput, ListOrdersQuery } from "./orders.schema";

const orderInclude = {
  items: {
    include: {
      product: {
        include: { images: { orderBy: { sortOrder: "asc" as const }, take: 1 } },
      },
    },
  },
};

// 장바구니 내용을 스냅샷하여 주문을 생성한다. 재고 검증, 재고 차감, 장바구니 비우기를
// 하나의 트랜잭션으로 묶어 중간에 실패해도 일부만 반영되지 않도록 한다.
export async function createOrder(userId: string, input: CreateOrderInput) {
  const cart = await prisma.cart.findUnique({
    where: { userId },
    include: { items: { include: { product: true } } },
  });

  if (!cart || cart.items.length === 0) {
    throw new BadRequestError("장바구니가 비어 있습니다.");
  }

  return prisma.$transaction(async (tx) => {
    let totalAmount = 0;
    for (const item of cart.items) {
      if (!item.product.isActive) {
        throw new BadRequestError(`판매가 중지된 상품이 포함되어 있습니다: ${item.product.name}`);
      }
      if (item.quantity > item.product.stock) {
        throw new BadRequestError(`재고가 부족합니다: ${item.product.name} (재고 ${item.product.stock}개)`);
      }
      totalAmount += item.product.price * item.quantity;
    }

    const order = await tx.order.create({
      data: {
        userId,
        totalAmount,
        shippingAddr: input.shippingAddr,
        items: {
          create: cart.items.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            priceAtOrder: item.product.price,
          })),
        },
      },
      include: orderInclude,
    });

    for (const item of cart.items) {
      await tx.product.update({
        where: { id: item.productId },
        data: { stock: { decrement: item.quantity } },
      });
    }

    await tx.cartItem.deleteMany({ where: { cartId: cart.id } });

    return order;
  });
}

export async function listOrders(userId: string, query: ListOrdersQuery) {
  const where = { userId };

  const [items, total] = await Promise.all([
    prisma.order.findMany({
      where,
      include: orderInclude,
      orderBy: { createdAt: "desc" },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    prisma.order.count({ where }),
  ]);

  return {
    items,
    page: query.page,
    pageSize: query.pageSize,
    total,
    totalPages: Math.max(1, Math.ceil(total / query.pageSize)),
  };
}

export async function getOrderById(userId: string, id: string) {
  const order = await prisma.order.findUnique({ where: { id }, include: orderInclude });
  if (!order || order.userId !== userId) {
    throw new NotFoundError("주문을 찾을 수 없습니다.");
  }
  return order;
}
