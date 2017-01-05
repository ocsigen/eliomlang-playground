
let%server y = Pure.x
let%client y = Pure.x
let%server () = Printf.printf "server: %i@." y
let%client () = Printf.printf "client: %i@." y
