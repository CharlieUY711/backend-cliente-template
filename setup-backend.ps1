$base = "C:\Carlos\Marketplace\backend-cliente-template"

# ── 00_core.sql ──────────────────────────────────────────────────────────────
Set-Content "$base\schema\00_core.sql" -Encoding UTF8 @'
-- =====================================================
-- 00_core.sql — Tablas base del cliente
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
'@

# ── 01_ecommerce.sql ─────────────────────────────────────────────────────────
Set-Content "$base\schema\01_ecommerce.sql" -Encoding UTF8 @'
-- =====================================================
-- 01_ecommerce.sql — eCommerce completo
-- Depende de: 00_core.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS categorias (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre      VARCHAR(255) NOT NULL,
  slug        VARCHAR(255) UNIQUE,
  descripcion TEXT,
  imagen_url  TEXT,
  padre_id    UUID REFERENCES categorias(id) ON DELETE SET NULL,
  orden       INTEGER DEFAULT 0,
  activo      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS productos (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre            VARCHAR(255) NOT NULL,
  slug              VARCHAR(255) UNIQUE,
  descripcion       TEXT,
  descripcion_corta TEXT,
  categoria_id      UUID REFERENCES categorias(id) ON DELETE SET NULL,
  precio            NUMERIC(12,2) NOT NULL DEFAULT 0,
  precio_oferta     NUMERIC(12,2),
  costo             NUMERIC(12,2),
  sku               VARCHAR(100) UNIQUE,
  codigo_barras     VARCHAR(100),
  stock             INTEGER DEFAULT 0,
  stock_minimo      INTEGER DEFAULT 0,
  peso              NUMERIC(8,3),
  dimensiones       JSONB,
  imagenes          JSONB DEFAULT '[]',
  atributos         JSONB DEFAULT '{}',
  variantes         JSONB DEFAULT '[]',
  tags              TEXT[],
  activo            BOOLEAN DEFAULT TRUE,
  destacado         BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS metodos_pago (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre     VARCHAR(100) NOT NULL,
  tipo       VARCHAR(50) NOT NULL,
  config     JSONB DEFAULT '{}',
  activo     BOOLEAN DEFAULT TRUE,
  orden      INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS metodos_envio (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre         VARCHAR(100) NOT NULL,
  tipo           VARCHAR(50) NOT NULL,
  precio_base    NUMERIC(10,2) DEFAULT 0,
  precio_kg      NUMERIC(10,2) DEFAULT 0,
  tiempo_entrega VARCHAR(100),
  zonas          JSONB DEFAULT '[]',
  config         JSONB DEFAULT '{}',
  activo         BOOLEAN DEFAULT TRUE,
  orden          INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pedidos (
  id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  numero_pedido      TEXT NOT NULL UNIQUE,
  estado             TEXT NOT NULL DEFAULT 'pendiente'
                     CHECK (estado IN ('pendiente','confirmado','preparando','listo','enviado','entregado','cancelado','devuelto')),
  estado_pago        TEXT NOT NULL DEFAULT 'pendiente'
                     CHECK (estado_pago IN ('pendiente','pagado','parcial','reembolsado','fallido')),
  cliente_persona_id UUID REFERENCES personas(id) ON DELETE SET NULL,
  cliente_org_id     UUID REFERENCES organizaciones(id) ON DELETE SET NULL,
  metodo_pago_id     UUID REFERENCES metodos_pago(id) ON DELETE SET NULL,
  metodo_envio_id    UUID REFERENCES metodos_envio(id) ON DELETE SET NULL,
  items              JSONB NOT NULL DEFAULT '[]',
  subtotal           NUMERIC(12,2) NOT NULL DEFAULT 0,
  descuento          NUMERIC(12,2) NOT NULL DEFAULT 0,
  impuestos          NUMERIC(12,2) NOT NULL DEFAULT 0,
  costo_envio        NUMERIC(12,2) NOT NULL DEFAULT 0,
  total              NUMERIC(12,2) NOT NULL DEFAULT 0,
  direccion_envio    JSONB,
  notas              TEXT,
  notas_internas     TEXT,
  metadata           JSONB DEFAULT '{}',
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS pedido_numero_seq START 1000;

CREATE OR REPLACE FUNCTION generar_numero_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.numero_pedido IS NULL OR NEW.numero_pedido = '' THEN
    NEW.numero_pedido := 'PED-' || LPAD(nextval('pedido_numero_seq')::TEXT, 5, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_numero_pedido
  BEFORE INSERT ON pedidos
  FOR EACH ROW EXECUTE FUNCTION generar_numero_pedido();

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_productos_updated BEFORE UPDATE ON productos FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_pedidos_updated   BEFORE UPDATE ON pedidos   FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria_id);
CREATE INDEX IF NOT EXISTS idx_productos_activo    ON productos(activo);
CREATE INDEX IF NOT EXISTS idx_productos_sku       ON productos(sku);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado      ON pedidos(estado);
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente     ON pedidos(cliente_persona_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_created     ON pedidos(created_at DESC);

ALTER TABLE categorias    ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE metodos_pago  ENABLE ROW LEVEL SECURITY;
ALTER TABLE metodos_envio ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos       ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso autenticado" ON categorias    FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON productos     FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON metodos_pago  FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON metodos_envio FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON pedidos       FOR ALL USING (auth.role() = 'authenticated');
'@

# ── 02_logistica.sql ─────────────────────────────────────────────────────────
Set-Content "$base\schema\02_logistica.sql" -Encoding UTF8 @'
-- =====================================================
-- 02_logistica.sql — Logistica y envios
-- Depende de: 00_core.sql, 01_ecommerce.sql
-- =====================================================

CREATE TABLE IF NOT EXISTS couriers (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre     VARCHAR(100) NOT NULL,
  codigo     VARCHAR(20) UNIQUE,
  tipo       VARCHAR(50) DEFAULT 'nacional',
  api_url    TEXT,
  api_key    TEXT,
  config     JSONB DEFAULT '{}',
  activo     BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shipments (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pedido_id       UUID REFERENCES pedidos(id) ON DELETE CASCADE,
  courier_id      UUID REFERENCES couriers(id) ON DELETE SET NULL,
  numero_tracking TEXT,
  estado          TEXT NOT NULL DEFAULT 'pendiente'
                  CHECK (estado IN ('pendiente','preparando','despachado','en_transito','entregado','fallido','devuelto')),
  origen          JSONB,
  destino         JSONB,
  peso            NUMERIC(8,3),
  dimensiones     JSONB,
  costo           NUMERIC(10,2),
  etiqueta_url    TEXT,
  eventos         JSONB DEFAULT '[]',
  fecha_despacho  TIMESTAMPTZ,
  fecha_entrega   TIMESTAMPTZ,
  notas           TEXT,
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emotiva_labels (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  token          TEXT NOT NULL UNIQUE,
  shipment_id    UUID REFERENCES shipments(id) ON DELETE SET NULL,
  sender_name    TEXT NOT NULL,
  recipient_name TEXT NOT NULL,
  message        TEXT,
  qr_url         TEXT,
  scanned        BOOLEAN DEFAULT FALSE,
  scanned_at     TIMESTAMPTZ,
  scanned_count  INTEGER DEFAULT 0,
  activo         BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER trg_shipments_updated BEFORE UPDATE ON shipments FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX IF NOT EXISTS idx_shipments_pedido   ON shipments(pedido_id);
CREATE INDEX IF NOT EXISTS idx_shipments_estado   ON shipments(estado);
CREATE INDEX IF NOT EXISTS idx_shipments_tracking ON shipments(numero_tracking);
CREATE INDEX IF NOT EXISTS idx_emotiva_token      ON emotiva_labels(token);

ALTER TABLE couriers       ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE emotiva_labels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso autenticado" ON couriers       FOR ALL    USING (auth.role() = 'authenticated');
CREATE POLICY "Acceso autenticado" ON shipments      FOR ALL    USING (auth.role() = 'authenticated');
CREATE POLICY "Lectura publica"    ON emotiva_labels FOR SELECT USING (true);
CREATE POLICY "Escritura auth"     ON emotiva_labels FOR ALL    USING (auth.role() = 'authenticated');
'@

# ── 03_marketing.sql ─────────────────────────────────────────────────────────
Set-Content "$base\schema\03_marketing.sql" -Encoding UTF8 @'
-- =====================================================
-- 03_marketing.sql — Marketing y RRSS
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
'@

# ── 04_herramientas.sql ──────────────────────────────────────────────────────
Set-Content "$base\schema\04_herramientas.sql" -Encoding UTF8 @'
-- =====================================================
-- 04_herramientas.sql — Herramientas y utilidades
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
'@

# ── README.md ────────────────────────────────────────────────────────────────
Set-Content "$base\README.md" -Encoding UTF8 @'
# backend-cliente-template

Template de backend para clientes de Charlie Marketplace Builder.
Cada cliente tiene su propio proyecto Supabase. El Orquestador ejecuta este template para provisionar el backend completo.

## Schemas — orden de ejecucion

| Archivo | Modulos | Depende de |
|---------|---------|------------|
| 00_core.sql | Personas, Organizaciones, Roles, Usuarios, KV Store | — |
| 01_ecommerce.sql | Productos, Categorias, Pedidos, Metodos pago/envio | 00_core |
| 02_logistica.sql | Couriers, Shipments, Etiqueta Emotiva | 00_core, 01_ecommerce |
| 03_marketing.sql | Campanias, Suscriptores, RRSS Config, Fidelizacion | 00_core |
| 04_herramientas.sql | QR Codes, Documentos, Presupuestos, Carga Masiva | 00_core |

## Como provisionar un cliente nuevo

1. Crear proyecto en Supabase
2. Ejecutar schemas en orden en el SQL Editor
3. Registrar supabaseUrl y supabaseKey en cliente_config de la Plataforma

## Edge Functions (proximo paso)

functions/
├── ecommerce/    → CRUD productos, pedidos
├── logistica/    → shipments, tracking, etiquetas
├── marketing/    → campanias, suscriptores, RRSS
└── herramientas/ → QR, documentos, presupuestos
'@

# ── .gitignore ───────────────────────────────────────────────────────────────
Set-Content "$base\.gitignore" -Encoding UTF8 @'
.env
.env.local
*.env
node_modules/
.DS_Store
'@

Write-Host "✅ Todos los archivos creados correctamente."
Get-ChildItem $base -Recurse | Select-Object FullName
