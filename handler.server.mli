type response

type handler =
  uri:Uri.t ->
  meth:Cohttp.Code.meth ->
  headers:Cohttp.Header.t ->
  body:string ->
  response Lwt.t

val server : ?debug:bool -> handler -> unit Lwt.t
val js_file : string
val js_response : response Lwt.t

open Tyxml
val not_found : response Lwt.t
val html :
  ?headers:Html_types.head_content_fun Html.elt list ->
  title:string ->
  [< `Body ] Tyxml_html.elt -> response Lwt.t
