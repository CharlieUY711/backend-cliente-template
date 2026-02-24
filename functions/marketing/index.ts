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