-- =====================================================
-- 00_core.sql â€” Tablas base del cliente
-- Ejecutar primero. Sin dependencias externas.
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS personas (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo              VARCHAR(50) NOT NULL DEFAULT 'cliente',
  nombre            VARCHAR(255) NOT NULL,
  apellido          VARCHAR(255),
  email             VARCHAR(255),
  telefono          VARCHAR(50),
  documento_tipo    VARCHAR(20),
  documento_numero  VARCHAR(50),
  fecha_nacimiento  DATE,
  genero            VARCHAR(20),
  nacionalidad      VARCHAR(100),
  direccion         JSONB,
  metadata          JSONB,
  activo            BOOLEAN DEFAULT TRUE,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizaciones (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre      VARCHAR(255) NOT NULL,
  rut         VARCHAR(50),
  email       VARCHAR(255),
  telefono    VARCHAR(50),
  sitio_web   VARCHAR(255),
  sector      VARCHAR(100),
  direccion   JSONB,
  contacto_id UUID REFERENCES personas(id) ON DELETE SET NULL,
  metadata    JSONB,
  activo      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS roles_contextuales (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  permisos    JSONB NOT NULL DEFAULT '[]',
  color       VARCHAR(20),
  descripcion TEXT,
  activo      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO roles_contextuales (nombre, permisos, color, descripcion) VALUES
  ('Admin',        '["*"]',                                          '#FF6835', 'Acceso total al sistema'),
  ('Operador',     '["pedidos.*","personas.*","organizaciones.*"]',   '#3B82F6', 'Gestion operativa diaria'),
  ('Vendedor',     '["pedidos.ver","pedidos.crear","personas.*"]',    '#10B981', 'Ventas y clientes'),
  ('Logistico',    '["pedidos.ver","shipments.*","couriers.ver"]',    '#8B5CF6', 'Logistica y envios'),
  ('Solo lectura', '["*.ver"]',                                      '#6B7280', 'Visualizacion unicamente')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS usuarios (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auth_id      UUID UNIQUE,
  nombre       VARCHAR(255) NOT NULL,
  email        VARCHAR(255) NOT NULL UNIQUE,
  rol_id       UUID REFERENCES roles_contextuales(id) ON DELETE SET NULL,
  activo       BOOLEAN DEFAULT TRUE,
  ultimo_login TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kv_store (
  key        TEXT PRIMARY KEY,
  value      JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personas_email  ON personas(email);
CREATE INDEX IF NOT EXISTS idx_personas_tipo   ON personas(tipo);
CREATE INDEX IF NOT EXISTS idx_personas_activo ON personas(activo);
CREATE INDEX IF NOT EXISTS idx_org_nombre      ON organizaciones(nombre);
CREATE INDEX IF NOT EXISTS idx_usuarios_email  ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol    ON usuarios(rol_id);

ALTER TABLE personas           ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizaciones     ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles_contextuales ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios           ENABLE ROW LEVEL SECURITY;
ALTER TABLE kv_store           ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso autenticado" ON personas           FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON organizaciones     FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON roles_contextuales FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON usuarios           FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON kv_store           FOR ALL USING (auth.role() = 'authenticated');
