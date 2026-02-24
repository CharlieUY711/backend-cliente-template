# setup-functions.ps1
$base = "C:\Carlos\Marketplace\backend-cliente-template\functions"

function Write-Function($path, $content) {
    $dir = Split-Path $path
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "OK $path"
}

$ecommerce = @"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const parts = url.pathname.replace(/^\/ecommerce\/?/, "").split("/");
  const recurso = parts[0];
  const id = parts[1] || null;
  const method = req.method;

  try {
    if (recurso === "categorias") {
      if (method === "GET") {
        const { data, error } = await supabase.from("categorias").select("*").order("nombre");
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("categorias").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("categorias").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("categorias").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "productos") {
      if (method === "GET") {
        const categoria_id = url.searchParams.get("categoria_id");
        let q = supabase.from("productos").select("*, categorias(nombre)").order("nombre");
        if (categoria_id) q = q.eq("categoria_id", categoria_id);
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("productos").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("productos").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("productos").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "pedidos") {
      if (method === "GET") {
        const estado = url.searchParams.get("estado");
        let q = supabase.from("pedidos").select("*, personas(nombre, email)").order("created_at", { ascending: false });
        if (estado) q = q.eq("estado", estado);
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("pedidos").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("pedidos").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
    }

    if (recurso === "metodos_pago") {
      if (method === "GET") {
        const { data, error } = await supabase.from("metodos_pago").select("*");
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("metodos_pago").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("metodos_pago").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("metodos_pago").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "metodos_envio") {
      if (method === "GET") {
        const { data, error } = await supabase.from("metodos_envio").select("*");
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("metodos_envio").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("metodos_envio").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("metodos_envio").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    return json({ ok: false, error: "Recurso no encontrado" }, 404);
  } catch (e) {
    return json({ ok: false, error: e.message }, 500);
  }
});
"@

$logistica = @"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const parts = url.pathname.replace(/^\/logistica\/?/, "").split("/");
  const recurso = parts[0];
  const id = parts[1] || null;
  const method = req.method;

  try {
    if (recurso === "couriers") {
      if (method === "GET") {
        const { data, error } = await supabase.from("couriers").select("*").order("nombre");
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("couriers").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("couriers").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("couriers").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "shipments") {
      if (method === "GET") {
        const estado = url.searchParams.get("estado");
        let q = supabase.from("shipments").select("*, couriers(nombre), pedidos(id, total)").order("created_at", { ascending: false });
        if (estado) q = q.eq("estado", estado);
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("shipments").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("shipments").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
    }

    if (recurso === "etiquetas") {
      if (method === "GET") {
        const shipment_id = url.searchParams.get("shipment_id");
        let q = supabase.from("emotiva_labels").select("*").order("created_at", { ascending: false });
        if (shipment_id) q = q.eq("shipment_id", shipment_id);
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("emotiva_labels").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("emotiva_labels").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    return json({ ok: false, error: "Recurso no encontrado" }, 404);
  } catch (e) {
    return json({ ok: false, error: e.message }, 500);
  }
});
"@

$marketing = @"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const parts = url.pathname.replace(/^\/marketing\/?/, "").split("/");
  const recurso = parts[0];
  const id = parts[1] || null;
  const method = req.method;

  try {
    if (recurso === "campanias") {
      if (method === "GET") {
        const { data, error } = await supabase.from("campanias").select("*").order("created_at", { ascending: false });
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("campanias").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("campanias").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("campanias").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "suscriptores") {
      if (method === "GET") {
        const activo = url.searchParams.get("activo");
        let q = supabase.from("suscriptores").select("*").order("created_at", { ascending: false });
        if (activo !== null) q = q.eq("activo", activo === "true");
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("suscriptores").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("suscriptores").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("suscriptores").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "rrss") {
      if (method === "GET") {
        const { data, error } = await supabase.from("rrss_config").select("*");
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("rrss_config").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("rrss_config").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("rrss_config").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "fidelizacion") {
      const sub = parts[1];
      if (sub === "config") {
        if (method === "GET") {
          const { data, error } = await supabase.from("fidelizacion_config").select("*").single();
          if (error) throw error;
          return json({ ok: true, data });
        }
        if (method === "PUT") {
          const body = await req.json();
          const { data, error } = await supabase.from("fidelizacion_config").upsert(body).select().single();
          if (error) throw error;
          return json({ ok: true, data });
        }
      }
      if (sub === "puntos") {
        if (method === "GET") {
          const persona_id = url.searchParams.get("persona_id");
          let q = supabase.from("fidelizacion_puntos").select("*, personas(nombre, email)");
          if (persona_id) q = q.eq("persona_id", persona_id);
          const { data, error } = await q;
          if (error) throw error;
          return json({ ok: true, data });
        }
        if (method === "POST") {
          const body = await req.json();
          const { data, error } = await supabase.from("fidelizacion_puntos").insert(body).select().single();
          if (error) throw error;
          return json({ ok: true, data }, 201);
        }
      }
    }

    return json({ ok: false, error: "Recurso no encontrado" }, 404);
  } catch (e) {
    return json({ ok: false, error: e.message }, 500);
  }
});
"@

$herramientas = @"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const parts = url.pathname.replace(/^\/herramientas\/?/, "").split("/");
  const recurso = parts[0];
  const id = parts[1] || null;
  const method = req.method;

  try {
    if (recurso === "qr") {
      if (method === "GET") {
        const { data, error } = await supabase.from("qr_codes").select("*").order("created_at", { ascending: false });
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("qr_codes").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("qr_codes").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "documentos") {
      if (method === "GET") {
        const tipo = url.searchParams.get("tipo");
        let q = supabase.from("documentos_generados").select("*").order("created_at", { ascending: false });
        if (tipo) q = q.eq("tipo", tipo);
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("documentos_generados").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("documentos_generados").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "presupuestos") {
      if (method === "GET") {
        const estado = url.searchParams.get("estado");
        let q = supabase.from("presupuestos").select("*, personas(nombre, email)").order("created_at", { ascending: false });
        if (estado) q = q.eq("estado", estado);
        const { data, error } = await q;
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("presupuestos").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("presupuestos").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "DELETE" && id) {
        const { error } = await supabase.from("presupuestos").delete().eq("id", id);
        if (error) throw error;
        return json({ ok: true });
      }
    }

    if (recurso === "carga_masiva") {
      if (method === "GET") {
        const { data, error } = await supabase.from("carga_masiva_jobs").select("*").order("created_at", { ascending: false });
        if (error) throw error;
        return json({ ok: true, data });
      }
      if (method === "POST") {
        const body = await req.json();
        const { data, error } = await supabase.from("carga_masiva_jobs").insert(body).select().single();
        if (error) throw error;
        return json({ ok: true, data }, 201);
      }
      if (method === "PUT" && id) {
        const body = await req.json();
        const { data, error } = await supabase.from("carga_masiva_jobs").update(body).eq("id", id).select().single();
        if (error) throw error;
        return json({ ok: true, data });
      }
    }

    return json({ ok: false, error: "Recurso no encontrado" }, 404);
  } catch (e) {
    return json({ ok: false, error: e.message }, 500);
  }
});
"@

Write-Function "$base\ecommerce\index.ts"    $ecommerce
Write-Function "$base\logistica\index.ts"    $logistica
Write-Function "$base\marketing\index.ts"    $marketing
Write-Function "$base\herramientas\index.ts" $herramientas

Write-Host ""
Write-Host "4 Edge Functions creadas. Ahora:"
Write-Host "  git add ."
Write-Host "  git commit -m feat-edge-functions"
Write-Host "  git push"
