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