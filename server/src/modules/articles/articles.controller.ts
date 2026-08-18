import type { Request, Response } from "express";
import * as articlesService from "./articles.service";
import type { CreateArticleInput, ListArticlesQuery, UpdateArticleInput } from "./articles.schema";

export async function listArticleCategoriesHandler(_req: Request, res: Response) {
  const categories = await articlesService.listArticleCategories();
  res.status(200).json(categories);
}

export async function listArticlesHandler(req: Request, res: Response) {
  const query = req.query as unknown as ListArticlesQuery;
  const includeInactive = query.includeInactive === true && req.user?.role === "ADMIN";
  const result = await articlesService.listArticles(query, includeInactive);
  res.status(200).json(result);
}

export async function getArticleHandler(req: Request, res: Response) {
  const includeInactive = req.user?.role === "ADMIN";
  const article = await articlesService.getArticleById(req.params.id, includeInactive);
  res.status(200).json(article);
}

export async function createArticleHandler(req: Request, res: Response) {
  const article = await articlesService.createArticle(
    req.user!.id,
    req.body as CreateArticleInput,
  );
  res.status(201).json(article);
}

export async function updateArticleHandler(req: Request, res: Response) {
  const article = await articlesService.updateArticle(req.params.id, req.body as UpdateArticleInput);
  res.status(200).json(article);
}

export async function deleteArticleHandler(req: Request, res: Response) {
  await articlesService.deleteArticle(req.params.id);
  res.status(204).send();
}
