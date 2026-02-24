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