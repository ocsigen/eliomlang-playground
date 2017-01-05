
open Lwt.Infix
open Cohttp
open Cohttp_lwt_unix
open Tyxml

type response =
  | File of string
  | Html of
      [`Title ] Html.elt *
        Html_types.head_content_fun Html.elt list *
        [ `Body ] Html.elt
  | NotFound

let file s = File s

let html ?(headers=[]) ~title body =
  Lwt.return @@
  Html (Html.title @@ Html.pcdata title, headers, (body :> [`Body] Html.elt))

let not_found = Lwt.return NotFound
let file s = Lwt.return (File s)


type handler =
  uri:Uri.t ->
  meth:Cohttp.Code.meth ->
  headers:Cohttp.Header.t ->
  body:string ->
  response Lwt.t

let js_file = "main.js"
let js_response = file js_file

let js_script =
  Html.(script ~a:[a_src js_file] (pcdata""))


let eliom_script ~debug reqdata =
  let gbldata = Eliom_runtime.Global_data.serial ~debug in
  let s = Eliom_runtime.eliom_script gbldata reqdata in
  Html.script (Html.cdata_script s)

let server ?(debug=false) (handler : handler) =
  let callback _conn req body =
    let uri = req |> Request.uri in
    let meth = req |> Request.meth in
    let headers = req |> Request.headers in
    let%lwt body = body |> Cohttp_lwt_body.to_string in
    let%lwt request_data, res =
      Eliom_lwt.handle_request ~debug @@ fun () ->
      handler ~uri ~meth ~headers ~body
    in
    match res with
    | File fname -> Server.respond_file ~fname ()
    | NotFound -> Server.respond_not_found ~uri ()
    | Html (title, headers, body) ->
      let headers' = eliom_script ~debug request_data :: js_script :: headers in
      let page = Html.html (Html.head title headers') body in
      let body = Format.asprintf "%a" (Html.pp ()) page in
      Server.respond_string ~status:`OK ~body ()
  in
  Server.create ~mode:(`TCP (`Port 8080)) (Server.make ~callback ())

