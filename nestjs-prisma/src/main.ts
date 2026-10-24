// Load .env for local development (Prisma 7 no longer does this itself).
// Variables already set in the environment take precedence.
import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  const port = Number(process.env.PORT) || 80;
  await app.listen(port, '0.0.0.0');
  console.log(`NestJS+Prisma listening on http://0.0.0.0:${port}`);
}

void bootstrap();
