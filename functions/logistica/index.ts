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