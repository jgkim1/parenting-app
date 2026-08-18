import type { Request, Response } from "express";
import * as productsService from "./products.service";
import type {
  CreateProductInput,
  CreateReviewInput,
  ListProductsQuery,
  UpdateProductInput,
  UpdateReviewInput,
} from "./products.schema";

export async function listCategoriesHandler(_req: Request, res: Response) {
  const categories = await productsService.listCategories();
  res.status(200).json(categories);
}

export async function listProductsHandler(req: Request, res: Response) {
  const query = req.query as unknown as ListProductsQuery;
  const includeInactive = query.includeInactive === true && req.user?.role === "ADMIN";
  const result = await productsService.listProducts(query, includeInactive);
  res.status(200).json(result);
}

export async function getProductHandler(req: Request, res: Response) {
  const includeInactive = req.user?.role === "ADMIN";
  const product = await productsService.getProductById(req.params.id, includeInactive);
  res.status(200).json(product);
}

export async function updateProductHandler(req: Request, res: Response) {
  const product = await productsService.updateProduct(
    req.user!.id,
    req.user!.role,
    req.params.id,
    req.body as UpdateProductInput,
  );
  res.status(200).json(product);
}

export async function createProductHandler(req: Request, res: Response) {
  const product = await productsService.createProduct(
    req.user!.id,
    req.body as CreateProductInput,
  );
  res.status(201).json(product);
}

export async function createReviewHandler(req: Request, res: Response) {
  const review = await productsService.createReview(
    req.user!.id,
    req.params.id,
    req.body as CreateReviewInput,
  );
  res.status(201).json(review);
}

export async function updateReviewHandler(req: Request, res: Response) {
  const review = await productsService.updateReview(
    req.user!.id,
    req.params.id,
    req.body as UpdateReviewInput,
  );
  res.status(200).json(review);
}

export async function deleteReviewHandler(req: Request, res: Response) {
  await productsService.deleteReview(req.user!.id, req.params.id);
  res.status(204).send();
}
