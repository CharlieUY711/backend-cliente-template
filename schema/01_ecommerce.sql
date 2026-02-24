-- =====================================================
-- 01_ecommerce.sql â€” eCommerce completo
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
