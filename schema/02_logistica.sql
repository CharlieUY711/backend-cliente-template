-- =====================================================
-- 02_logistica.sql â€” Logistica y envios
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
