# backend-cliente-template

Template de backend para clientes de Charlie Marketplace Builder.
Cada cliente tiene su propio proyecto Supabase. El Orquestador ejecuta este template para provisionar el backend completo.

## Schemas â€” orden de ejecucion

| Archivo | Modulos | Depende de |
|---------|---------|------------|
| 00_core.sql | Personas, Organizaciones, Roles, Usuarios, KV Store | â€” |
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
â”œâ”€â”€ ecommerce/    â†’ CRUD productos, pedidos
â”œâ”€â”€ logistica/    â†’ shipments, tracking, etiquetas
â”œâ”€â”€ marketing/    â†’ campanias, suscriptores, RRSS
â””â”€â”€ herramientas/ â†’ QR, documentos, presupuestos
