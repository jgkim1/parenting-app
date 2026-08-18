import type { Request, Response } from "express";
import * as childrenService from "./children.service";
import type { CreateChildInput, UpdateChildInput } from "./children.schema";

export async function listChildrenHandler(req: Request, res: Response) {
  const children = await childrenService.listChildren(req.user!.id);
  res.status(200).json(children);
}

export async function createChildHandler(req: Request, res: Response) {
  const child = await childrenService.createChild(req.user!.id, req.body as CreateChildInput);
  res.status(201).json(child);
}

export async function updateChildHandler(req: Request, res: Response) {
  const child = await childrenService.updateChild(
    req.user!.id,
    req.params.id,
    req.body as UpdateChildInput,
  );
  res.status(200).json(child);
}

export async function deleteChildHandler(req: Request, res: Response) {
  await childrenService.deleteChild(req.user!.id, req.params.id);
  res.status(204).send();
}
