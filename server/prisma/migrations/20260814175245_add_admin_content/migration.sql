-- CreateEnum
CREATE TYPE "AdPlacement" AS ENUM ('TODAY', 'PRODUCT_LIST', 'ARTICLE_LIST', 'COMMUNITY_LIST', 'PRODUCT_DETAIL', 'POST_DETAIL');

-- AlterTable
ALTER TABLE "Article" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "Ad" (
    "id" TEXT NOT NULL,
    "placement" "AdPlacement" NOT NULL,
    "title" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "linkUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Ad_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Ad_placement_idx" ON "Ad"("placement");

