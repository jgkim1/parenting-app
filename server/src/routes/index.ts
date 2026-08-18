import { Router } from "express";
import { authRouter } from "../modules/auth/auth.routes";
import { meRouter } from "../modules/users/users.routes";
import { categoriesRouter, productsRouter, reviewsRouter } from "../modules/products/products.routes";
import { articleCategoriesRouter, articlesRouter } from "../modules/articles/articles.routes";
import { cartRouter } from "../modules/cart/cart.routes";
import { ordersRouter } from "../modules/orders/orders.routes";
import { commentsRouter, postsRouter } from "../modules/community/community.routes";
import { uploadsRouter } from "../modules/uploads/uploads.routes";
import { childrenRouter } from "../modules/children/children.routes";
import { adsRouter } from "../modules/ads/ads.routes";

export const apiRouter = Router();

apiRouter.use("/auth", authRouter);
apiRouter.use("/users", meRouter);
apiRouter.use("/categories", categoriesRouter);
apiRouter.use("/products", productsRouter);
apiRouter.use("/reviews", reviewsRouter);
apiRouter.use("/article-categories", articleCategoriesRouter);
apiRouter.use("/articles", articlesRouter);
apiRouter.use("/cart", cartRouter);
apiRouter.use("/orders", ordersRouter);
apiRouter.use("/posts", postsRouter);
apiRouter.use("/comments", commentsRouter);
apiRouter.use("/uploads", uploadsRouter);
apiRouter.use("/children", childrenRouter);
apiRouter.use("/ads", adsRouter);
