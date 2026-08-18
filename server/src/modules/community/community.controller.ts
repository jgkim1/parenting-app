import type { Request, Response } from "express";
import * as communityService from "./community.service";
import type {
  CreateCommentInput,
  CreatePostInput,
  ListPostsQuery,
  UpdatePostInput,
} from "./community.schema";

export async function listPostsHandler(req: Request, res: Response) {
  const result = await communityService.listPosts(req.query as unknown as ListPostsQuery);
  res.status(200).json(result);
}

export async function getPostHandler(req: Request, res: Response) {
  const post = await communityService.getPostById(req.params.id, req.user?.id);
  res.status(200).json(post);
}

export async function createPostHandler(req: Request, res: Response) {
  const post = await communityService.createPost(req.user!.id, req.body as CreatePostInput);
  res.status(201).json(post);
}

export async function updatePostHandler(req: Request, res: Response) {
  const post = await communityService.updatePost(
    req.user!.id,
    req.params.id,
    req.body as UpdatePostInput,
  );
  res.status(200).json(post);
}

export async function deletePostHandler(req: Request, res: Response) {
  await communityService.deletePost(req.user!.id, req.params.id);
  res.status(204).send();
}

export async function addCommentHandler(req: Request, res: Response) {
  const comment = await communityService.addComment(
    req.user!.id,
    req.params.id,
    req.body as CreateCommentInput,
  );
  res.status(201).json(comment);
}

export async function deleteCommentHandler(req: Request, res: Response) {
  await communityService.deleteComment(req.user!.id, req.params.id);
  res.status(204).send();
}

export async function toggleLikeHandler(req: Request, res: Response) {
  const result = await communityService.toggleLike(req.user!.id, req.params.id);
  res.status(200).json(result);
}
