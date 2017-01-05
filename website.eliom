open Tyxml


let%server handler ~uri ~meth ~headers ~body =
  match Uri.path uri with

  | s when s = "/" ^ Handler.js_file ->
    Handler.js_response

  | "" | "/" | "index.html" ->
    let _ = [%client
      print_endline ("patapon: " ^ ~%(Uri.path uri))
    ] in
    Handler.html ~title:"hello" Html.(body [h1 [pcdata "Hello!"]])

  | _ ->
    Handler.not_found

let%server () = Lwt_main.run @@ Handler.server handler
let%client () = Eliom_runtime.init ()
