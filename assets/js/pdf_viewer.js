const PDFJS_VERSION = "2.15.306";
const PDFJS_CDN = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${PDFJS_VERSION}`;
const PAGE_HASH_REGEX = /\/page\/(\d+)/;

import {addEvents, removeEvents} from './utils';
import {getState, setState, resetState} from './store';
import * as pdfjsLib from '../vendor/pdfjs-dist/2.15.306/build/pdf.js';
import {PDFViewer, EventBus, PDFLinkService} from '../vendor/pdfjs-dist/2.15.306/web/pdf_viewer.js';

const loadDocument = async (el, url) => {
    pdfjsLib.GlobalWorkerOptions.workerSrc =
        `/assets/pdf.worker.js`;

    const eventBus = new EventBus();

    // PDF Link Service (Not sure if this is necessary)...
    const pdfLinkService = new PDFLinkService({ eventBus });

    // PDF Viewer
    const pdfViewer = new PDFViewer({
        container: el,
        eventBus,
        enableWebGL: true,
        textLayerMode: 2,
        removePageBorders: true,
        enableScripting: false,
        renderInteractiveForms: false,
        linkService: pdfLinkService,
    });

    setState({
        pdfViewer
    });

    pdfLinkService.setViewer(pdfViewer);

    eventBus.on("pagesloaded", onPagesLoaded(el));

    const pdf = await pdfjsLib
        .getDocument({url, disableStream: false, disableAutoFetch: true})
        .promise;

    pdfViewer.setDocument(pdf);

    pdfLinkService.setDocument(pdf, null);
    return {pdf};
}

const onCurrentPageInputChange = (e) => {
    const page = parseInt(e.target.value, 10);

    if(!isNaN(page)) {
        window.location.hash = `/page/${page}`;
    }
};

const onToggleResize = (el) => () => {
    const {
        pdfViewer,
        currentPage,
    } = getState();

    // "auto" | "page-fit" | "page-width"
    if (pdfViewer.currentScaleValue == "page-width") {
        pdfViewer.currentScaleValue = "auto"
    } else {
        pdfViewer.currentScaleValue = "page-width"
    }
    pdfViewer.update();

    setTimeout(() =>
        scrollPageIntoView(el, currentPage)
    , 0);
};

const onPagesLoaded = (el) => () => {
    const {
        pdfViewer,
        currentPage
    } = getState();

    onWindowResize();
    // Scroll to stored page page
    // We most likely want to store more specific data, e.g.
    // if a user is 90% through a page, storing the page number doesn't cut
    // it. Instead we need to normalize to some degree of precision.
    scrollPageIntoView(el, currentPage);

    // TODO we most likely need to track the direction of the page scroll, otherwise there's an issue with page jumping
    // Another option is instead of using IntersectionObserver, we just track scrolling
    const observer = new IntersectionObserver(onNewPage, {
        root: document.getElementById("document-viewer"),
        rootMargin: '0px',
        threshold: [.51]
    });

    document.querySelectorAll('.page').forEach(p => {
        observer.observe(p);
    });

    /*
    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            const id = entry.target.getAttribute('id');
            if (entry.intersectionRatio > 0) {
                document.querySelector(`nav li a[href="#${id}"]`).parentElement.classList.add('active');
            } else {
                document.querySelector(`nav li a[href="#${id}"]`).parentElement.classList.remove('active');
            }
        });
    });
    */

};

const scrollPageIntoView = (el, pageNumber) => {
    const page = el 
        .querySelector(`[data-page-number="${pageNumber}"][class="page"]`)
    if (page) {
        page.scrollIntoView();
    }
}

const onWindowResize = () => {
    const {
        pdfViewer,
        currentPage
    } = getState();

    pdfViewer.updateContainerHeightCss();

    const currentScaleValue = pdfViewer.currentScaleValue;
    if (currentScaleValue == "page-width") {
        pdfViewer.update();
    }

};

const onNewPage = (e) => {
    const {hook} = getState();
    if (e.length == 0)
        return;

    const pageNumber = e[0].target.dataset.pageNumber;

    if (parseInt(pageNumber, 10) == 1)
        return;

    hook.pushEventTo(hook.el, "update-current-page", {pageNumber: pageNumber}, (reply, ref) => {});
    // TODO refactor all of this currentPage state management into some reactive hodgepodge
    if (history && history.pushState) {
        history.pushState(null, null, `#/page/${pageNumber}`);
    }
    document.getElementById("current-page").value=pageNumber;

    const toc = document.getElementById("toolbar-toc");
    if (toc) {
        
    }

    setState({
        currentPage: pageNumber
    });
};

async function flattenOutline(pdf, items, level = 0) {
    if (!items) {
        return [];
    }

    if (!Array.isArray(items)) {
        // https://github.com/caddishouse/www/issues/51
        // it's possible for getPageIndex to fail
        try { 
            return [
                {
                    title: items.title,
                    page: await pdf.getPageIndex(items.dest[0]) + 1,
                    dest: items.dest,
                    level: level
                }
            ];
        } catch (e) {
            console.error(`
                Error grabbing pageIndex for outline items

                ${JSON.stringify(items)}
                ${e}

                Please report the above to:
                https://github.com/caddishouse/www/issues
            `);
            return [];
        }
    }

    const [head, ...tail] = items;
    if (!head) {
        return [];
    }


    const a = await flattenOutline(pdf, head, level);
    const b = await flattenOutline(pdf, head["items"], level + 1)
    const c = await flattenOutline(pdf, tail, level)

    return a.concat(b).concat(c);
}

exports.PDFViewer = {
    async mounted() {
        resetState();

        const url = this.el.dataset.mediaUrl;
        const isMetadataLoaded = "metadataLoaded" in this.el.dataset;
        const currentPage = this.el.dataset.currentPage;

        setState({
            currentPage,
            hook: this,
            pdfViewer: null,
        })

        const {
            pdf
        } = await loadDocument(this.el, url);

        if (!isMetadataLoaded) {
            const totalPages = pdf.numPages;
            const outline = await pdf.getOutline();
            const outlineData = await flattenOutline(pdf, outline);

            this.pushEventTo(this.el, "document-loaded", {outline: outlineData, totalPages}, (reply, ref) => {});
        }

        this.events = [
            [window, 'caddishouse:resize-pdf', onToggleResize(this.el)], 
            [window, "resize", onWindowResize],
            [window, "hashchange", (e) => {
                if (e.newURL != e.oldURL) {
                    const matches = e.newURL.match(PAGE_HASH_REGEX);
                    if (matches.length == 2) {
                        scrollPageIntoView(this.el, parseInt(matches[1], 10));
                    }
                }
            }],
            [document.getElementById("current-page"), "input", onCurrentPageInputChange], // debounce
            [document.getElementById("current-page"), "keyup", onCurrentPageInputChange], // debounce
        ];

        addEvents(this.events);
    },

    destroyed() {
        removeEvents(this.events);
        this.events = [];
    }
};
