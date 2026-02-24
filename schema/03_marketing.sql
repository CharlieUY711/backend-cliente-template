-- =====================================================
-- 03_marketing.sql â€” Marketing y RRSS
-- Depende de: 00_core.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS campanias (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre       VARCHAR(255) NOT NULL,
  tipo         VARCHAR(50) NOT NULL,
  estado       VARCHAR(50) DEFAULT 'borrador',
  audiencia    JSONB DEFAULT '{}',
  contenido    JSONB DEFAULT '{}',
  config       JSONB DEFAULT '{}',
  fecha_inicio TIMESTAMPTZ,
  fecha_fin    TIMESTAMPTZ,
  metricas     JSONB DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS suscriptores (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email      VARCHAR(255) NOT NULL UNIQUE,
  nombre     VARCHAR(255),
  estado     VARCHAR(20) DEFAULT 'activo',
  listas     TEXT[] DEFAULT '{}',
  metadata   JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rrss_config (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  plataforma    VARCHAR(50) NOT NULL UNIQUE,
  app_id        TEXT,
  app_secret    TEXT,
  access_token  TEXT,
  account_id    TEXT,
  page_id       TEXT,
  verificado    BOOLEAN DEFAULT FALSE,
  verificado_at TIMESTAMPTZ,
  account_name  TEXT,
  estado        VARCHAR(20) DEFAULT 'no_configurado',
  error         TEXT,
  saved_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO rrss_config (plataforma, estado) VALUES
  ('instagram', 'no_configurado'),
  ('facebook',  'no_configurado'),
  ('whatsapp',  'no_configurado')
ON CONFLICT (plataforma) DO NOTHING;

CREATE TABLE IF NOT EXISTS fidelizacion_config (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  activo          BOOLEAN DEFAULT FALSE,
  puntos_por_peso NUMERIC(6,2) DEFAULT 1,
  niveles         JSONB DEFAULT '[]',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fidelizacion_puntos (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  persona_id  UUID REFERENCES personas(id) ON DELETE CASCADE,
  pedido_id   UUID REFERENCES pedidos(id) ON DELETE SET NULL,
  puntos      INTEGER NOT NULL,
  tipo        VARCHAR(20) DEFAULT 'ganados',
  descripcion TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campanias_estado     ON campanias(estado);
CREATE INDEX IF NOT EXISTS idx_suscriptores_email   ON suscriptores(email);
CREATE INDEX IF NOT EXISTS idx_fidelizacion_persona ON fidelizacion_puntos(persona_id);

ALTER TABLE campanias           ENABLE ROW LEVEL SECURITY;
ALTER TABLE suscriptores        ENABLE ROW LEVEL SECURITY;
ALTER TABLE rrss_config         ENABLE ROW LEVEL SECURITY;
ALTER TABLE fidelizacion_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE fidelizacion_puntos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso autenticado" ON campanias           FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON suscriptores        FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON rrss_config         FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON fidelizacion_config FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON fidelizacion_puntos FOR ALL USING (auth.role() = 'authenticated');
