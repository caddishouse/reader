import 'phoenix_html';
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {PDFViewer} from "./pdf_viewer";
import {CommandPalette} from "./command_palette";
import {Toolbar} from "./toolbar";
import {Flash} from "./flash";
import "./polyfills";

/* TOPBAR */
import topbar from "../vendor/topbar1.0.0"

topbar.config({
  barColors: { 0: '#818cf8' },
  shadowColor: 'rgba(0, 0, 0, .3)',
});
/* END TOPBAR */

window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

const hooks = {
    PDFViewer,
    CommandPalette,
    Toolbar,
    Flash
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    hooks, 
    params: {_csrf_token: csrfToken},
    metadata: {
        keydown: (e, el) => {
            return {
                key: e.key,
                metaKey: e.metaKey,
                repeat: e.repeat
            }
        }
    }
})
liveSocket.connect()
