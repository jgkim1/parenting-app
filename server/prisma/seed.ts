import { PrismaClient } from "@prisma/client";
import { hashPassword } from "../src/common/utils/hash";

const prisma = new PrismaClient();

const CATEGORIES = [
  { name: "기저귀/물티슈", slug: "diapers-wipes" },
  { name: "분유/이유식", slug: "formula-food" },
  { name: "유아 의류", slug: "baby-clothes" },
  { name: "완구/교육", slug: "toys-education" },
  { name: "안전/외출용품", slug: "safety-outdoor" },
];

const SAMPLE_PRODUCTS: Array<{
  categorySlug: string;
  name: string;
  description: string;
  price: number;
  stock: number;
  imageUrl: string;
}> = [
  {
    categorySlug: "diapers-wipes",
    name: "밴드형 기저귀 4단계 대형 (60매)",
    description: "통기성이 뛰어난 밴드형 기저귀입니다. 하루 종일 뽀송함을 유지해줍니다.",
    price: 32900,
    stock: 150,
    imageUrl: "https://placehold.co/600x600?text=Diapers",
  },
  {
    categorySlug: "formula-food",
    name: "단계별 유기농 이유식 파우치 세트",
    description: "6개월부터 먹일 수 있는 유기농 인증 이유식 파우치 10개 세트입니다.",
    price: 24900,
    stock: 80,
    imageUrl: "https://placehold.co/600x600?text=Baby+Food",
  },
  {
    categorySlug: "baby-clothes",
    name: "오가닉 코튼 우주복 세트 (2벌)",
    description: "신생아 피부에 순한 오가닉 코튼 소재의 우주복 2벌 세트입니다.",
    price: 39000,
    stock: 60,
    imageUrl: "https://placehold.co/600x600?text=Baby+Clothes",
  },
  {
    categorySlug: "toys-education",
    name: "원목 소리나는 딸랑이 장난감",
    description: "아기 손에 쥐기 좋은 크기의 원목 딸랑이로, 두뇌 발달에 도움을 줍니다.",
    price: 15900,
    stock: 200,
    imageUrl: "https://placehold.co/600x600?text=Toy",
  },
  {
    categorySlug: "safety-outdoor",
    name: "휴대용 접이식 유모차",
    description: "한 손으로 접고 펼 수 있는 초경량 휴대용 유모차입니다.",
    price: 189000,
    stock: 25,
    imageUrl: "https://placehold.co/600x600?text=Stroller",
  },
];

const ARTICLE_CATEGORIES = [
  { name: "신생아 케어", slug: "newborn-care" },
  { name: "수면교육", slug: "sleep-training" },
  { name: "이유식/영양", slug: "nutrition" },
  { name: "발달/놀이", slug: "development-play" },
  { name: "건강/예방접종", slug: "health-vaccination" },
];

const SAMPLE_ARTICLES: Array<{
  categorySlug: string;
  title: string;
  content: string;
  thumbnailUrl: string;
}> = [
  {
    categorySlug: "newborn-care",
    title: "신생아 목욕, 이렇게 하면 안전해요",
    content:
      "신생아 목욕은 배꼽이 떨어지기 전까지는 스펀지 목욕으로 시작하는 것이 안전합니다. 물 온도는 37~38도가 적당하며, 목욕 시간은 5~10분을 넘기지 않는 것이 좋습니다. 목욕 후에는 보습제를 충분히 발라주세요.",
    thumbnailUrl: "https://placehold.co/800x450?text=Newborn+Care",
  },
  {
    categorySlug: "sleep-training",
    title: "월령별 수면 패턴과 통잠 만들기",
    content:
      "생후 4~6개월부터는 규칙적인 낮잠·밤잠 루틴을 만들어주는 것이 통잠에 도움이 됩니다. 잠들기 전 목욕, 수유, 자장가 등 일정한 순서를 반복하면 아기가 잠들 시간을 예측하고 편안해합니다.",
    thumbnailUrl: "https://placehold.co/800x450?text=Sleep+Training",
  },
  {
    categorySlug: "nutrition",
    title: "이유식 시작 시기와 순서 가이드",
    content:
      "이유식은 생후 6개월 전후, 목을 잘 가누고 음식에 관심을 보일 때 시작하는 것이 좋습니다. 쌀미음부터 시작해 알레르기 반응을 하루 이상 관찰한 뒤 새로운 재료를 하나씩 추가해주세요.",
    thumbnailUrl: "https://placehold.co/800x450?text=Baby+Nutrition",
  },
  {
    categorySlug: "development-play",
    title: "월령별 두뇌 발달 놀이 추천",
    content:
      "생후 3~6개월에는 딸랑이처럼 소리와 색이 뚜렷한 장난감이 시각·청각 발달에 도움이 됩니다. 7개월 이후에는 까꿍 놀이, 블록 쌓기처럼 원인과 결과를 경험할 수 있는 놀이를 추천합니다.",
    thumbnailUrl: "https://placehold.co/800x450?text=Baby+Play",
  },
  {
    categorySlug: "health-vaccination",
    title: "영유아 필수 예방접종 일정 정리",
    content:
      "B형간염, BCG, DTaP 등 국가필수예방접종은 정해진 시기에 맞춰 접종하는 것이 중요합니다. 접종 전후 아기의 컨디션을 살피고, 발열 등 이상 반응이 있으면 즉시 소아과에 문의하세요.",
    thumbnailUrl: "https://placehold.co/800x450?text=Vaccination",
  },
];

async function main() {
  const seller = await prisma.user.upsert({
    where: { email: "seller@example.com" },
    update: {},
    create: {
      email: "seller@example.com",
      passwordHash: await hashPassword("password123"),
      nickname: "육아용품 스토어",
      role: "SELLER",
    },
  });

  const admin = await prisma.user.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: {
      email: "admin@example.com",
      passwordHash: await hashPassword("password123"),
      nickname: "육아앱 편집팀",
      role: "ADMIN",
    },
  });

  const categoriesBySlug = new Map<string, { id: string }>();
  for (const category of CATEGORIES) {
    const created = await prisma.category.upsert({
      where: { slug: category.slug },
      update: { name: category.name },
      create: category,
    });
    categoriesBySlug.set(category.slug, created);
  }

  for (const product of SAMPLE_PRODUCTS) {
    const category = categoriesBySlug.get(product.categorySlug);
    if (!category) continue;

    const existing = await prisma.product.findFirst({
      where: { name: product.name, sellerId: seller.id },
    });
    if (existing) continue;

    await prisma.product.create({
      data: {
        sellerId: seller.id,
        categoryId: category.id,
        name: product.name,
        description: product.description,
        price: product.price,
        stock: product.stock,
        images: { create: [{ url: product.imageUrl, sortOrder: 0 }] },
      },
    });
  }

  const articleCategoriesBySlug = new Map<string, { id: string }>();
  for (const category of ARTICLE_CATEGORIES) {
    const created = await prisma.articleCategory.upsert({
      where: { slug: category.slug },
      update: { name: category.name },
      create: category,
    });
    articleCategoriesBySlug.set(category.slug, created);
  }

  for (const article of SAMPLE_ARTICLES) {
    const category = articleCategoriesBySlug.get(article.categorySlug);
    if (!category) continue;

    const existing = await prisma.article.findFirst({
      where: { title: article.title, authorId: admin.id },
    });
    if (existing) continue;

    await prisma.article.create({
      data: {
        authorId: admin.id,
        categoryId: category.id,
        title: article.title,
        content: article.content,
        thumbnailUrl: article.thumbnailUrl,
      },
    });
  }

  console.log(
    "시드 완료: 상품 카테고리 %d개, 상품 %d개, 정보 카테고리 %d개, 아티클 %d개",
    CATEGORIES.length,
    SAMPLE_PRODUCTS.length,
    ARTICLE_CATEGORIES.length,
    SAMPLE_ARTICLES.length,
  );
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
