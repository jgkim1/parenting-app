import type { Request, Response } from "express";
import * as adsService from "./ads.service";
import type { CreateAdInput, ListAdsQuery, UpdateAdInput } from "./ads.schema";

export async function listAdsHandler(req: Request, res: Response) {
  const query = req.query as unknown as ListAdsQuery;
  const includeInactive = query.includeInactive === true && req.user?.role === "ADMIN";
  const result = await adsService.listAds(query, includeInactive);
  res.status(200).json(result);
}

export async function createAdHandler(req: Request, res: Response) {
  const ad = await adsService.createAd(req.body as CreateAdInput);
  res.status(201).json(ad);
}

export async function updateAdHandler(req: Request, res: Response) {
  const ad = await adsService.updateAd(req.params.id, req.body as UpdateAdInput);
  res.status(200).json(ad);
}

export async function deleteAdHandler(req: Request, res: Response) {
  await adsService.deleteAd(req.params.id);
  res.status(204).send();
}
