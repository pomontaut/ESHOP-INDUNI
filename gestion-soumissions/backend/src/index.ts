import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import { env } from "./lib/env";
import { authRouter } from "./routes/auth";
import { submissionsRouter } from "./routes/submissions";
import { sourcingRouter } from "./routes/sourcing";
import { lotsRouter } from "./routes/lots";
import { suiviRouter } from "./routes/suivi";

const app = express();

app.use(cors({ origin: env.clientOrigin, credentials: true }));
app.use(express.json());
app.use(cookieParser());

app.get("/api/health", (_req, res) => res.json({ ok: true }));

app.use("/api/auth", authRouter);
app.use("/api/submissions", submissionsRouter);
app.use("/api/sourcing", sourcingRouter);
app.use("/api", lotsRouter);
app.use("/api", suiviRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: "Erreur interne du serveur." });
});

app.listen(env.port, () => {
  console.log(`Gestion des soumissions — API en écoute sur http://localhost:${env.port}`);
});
