import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  const port = Number(process.env.PORT) || 80;
  await app.listen(port, '0.0.0.0');
  console.log(`NestJS+Prisma listening on http://0.0.0.0:${port}`);
}

bootstrap();
