# 1. Aşama: Bağımlılıkları kur ve projeyi derle (Builder)
FROM node:20-alpine AS builder
WORKDIR /app

# Paket dosyalarını ve gerekli yamaları kopyala
COPY package*.json ./
COPY patches ./patches/
COPY prisma ./prisma/

# Bağımlılıkları temiz bir şekilde kur
RUN npm ci

# Projenin tüm kaynak kodlarını kopyala
COPY . .

# Prisma client'ını oluştur ve Next.js uygulamasını derle
RUN npx prisma generate
RUN npm run build

# 2. Aşama: Çalışma Ortamı (Runner)
FROM node:20-alpine AS runner
WORKDIR /app

# ÇOK ÖNEMLİ: Tüm dosyaları "builder" aşamasından (--from=builder) kopyalıyoruz
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/src ./src
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/public ./public
COPY --from=builder /app/tsconfig.json ./
COPY --from=builder /app/scripts ./scripts

# Çevre değişkenlerini ayarla
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Uygulamanın dışarıya açılacağı port
EXPOSE 3000

# Veritabanını güncelle, admin kullanıcısını oluştur ve custom server'ı başlat
CMD ["sh", "-c", "npx prisma db push && (if [ -n \"$ADMIN_EMAIL\" ] && [ -n \"$ADMIN_PASSWORD\" ]; then node scripts/setup-admin.js \"$ADMIN_EMAIL\" \"$ADMIN_PASSWORD\"; fi) && npx tsx src/server/index.ts"]
