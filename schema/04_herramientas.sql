-- =====================================================
-- 04_herramientas.sql â€” Herramientas y utilidades
-- Depende de: 00_core.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS qr_codes (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo       VARCHAR(50) NOT NULL,
  contenido  TEXT NOT NULL,
  url_corta  TEXT UNIQUE,
  qr_url     TEXT,
  escaneos   INTEGER DEFAULT 0,
  activo     BOOLEAN DEFAULT TRUE,
  metadata   JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS documentos_generados (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo       VARCHAR(50) NOT NULL,
  nombre     VARCHAR(255) NOT NULL,
  url        TEXT,
  metadata   JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS presupuestos (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  numero       TEXT NOT NULL UNIQUE,
  cliente_id   UUID REFERENCES personas(id) ON DELETE SET NULL,
  org_id       UUID REFERENCES organizaciones(id) ON DELETE SET NULL,
  estado       VARCHAR(30) DEFAULT 'borrador',
  items        JSONB NOT NULL DEFAULT '[]',
  subtotal     NUMERIC(12,2) DEFAULT 0,
  descuento    NUMERIC(12,2) DEFAULT 0,
  impuestos    NUMERIC(12,2) DEFAULT 0,
  total        NUMERIC(12,2) DEFAULT 0,
  validez_dias INTEGER DEFAULT 30,
  notas        TEXT,
  pdf_url      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS carga_masiva_jobs (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo        VARCHAR(50) NOT NULL,
  archivo_url TEXT,
  estado      VARCHAR(20) DEFAULT 'pendiente',
  total       INTEGER DEFAULT 0,
  procesados  INTEGER DEFAULT 0,
  errores     JSONB DEFAULT '[]',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE qr_codes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos_generados ENABLE ROW LEVEL SECURITY;
ALTER TABLE presupuestos         ENABLE ROW LEVEL SECURITY;
ALTER TABLE carga_masiva_jobs    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso autenticado" ON qr_codes             FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON documentos_generados FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON presupuestos         FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON carga_masiva_jobs    FOR ALL USING (auth.role() = 'authenticated');
