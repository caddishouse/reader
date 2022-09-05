import {isStorageAvailable} from "./localstorage";
import {addEvents, removeEvents} from './utils';
const LOCAL_STORAGE_KEY = "toolbar";
function handleDragAndDrop(el) {
    let viewport = {
        top: 0,
        left: 0,
    };
    // Commented out portion here is preferable but cannot be used just yet.
    // https://caniuse.com/mdn-api_element_computedstylemap
    // const style = el.computedStyleMap();
    const bbox = el.getBoundingClientRect();

    const dragStart = (e) => {
        if (e.target.tagName.toLowerCase() != "div")
            return;
        viewport.bottom = window.innerHeight;
        viewport.right = window.innerWidth;
        //toolBar.style.transform = `translate(${e.clientX - x}px, ${e.clientY - y}px)`;
        document.addEventListener('mousemove', dragMove, true);
        document.addEventListener('mouseup', dragEnd, true);
    };

    const dragMove = (e) => {
        // See comments above line `const style = el.computedStyleMap();`
        // const offsetY = style.get('transform')[0].y.value;
        // const offsetX = style.get('transform')[0].x.value;
        const style = new DOMMatrixReadOnly(getComputedStyle(el).transform);

        const offsetY = style.m42;
        const offsetX = style.m41;

        const newOffsetY = offsetY + e.movementY;
        const newOffsetX = offsetX + e.movementX;

        /*
        // Disable constraints for now -- it's too easy for the toolbar to get caught outside the window
        if (newOffsetX + bbox.left > viewport.left && 
            newOffsetX + bbox.right < viewport.right &&
            newOffsetY + bbox.top > viewport.top && 
            newOffsetY + bbox.bottom < viewport.bottom
        ) {
            el.style.transform = `translate(${newOffsetX}px, ${newOffsetY}px)`;
        }
        */
        el.style.transform = `translate(${newOffsetX}px, ${newOffsetY}px)`;
    };

    const dragEnd = (e) => {
        if (isStorageAvailable('localStorage')) {
            const bbox = el.getBoundingClientRect();
            localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(bbox));
        }

        document.removeEventListener('mousemove', dragMove, true);
        document.removeEventListener('mouseup', dragEnd, true);
    }

    el.addEventListener('mousedown', dragStart);
}

const handleKeyboardEvent = (hook) => (event) => {
    // Ignore if following modifier is active.
    if (event.getModifierState("Fn") ||
        event.getModifierState("Hyper") ||
        event.getModifierState("OS") ||
        event.getModifierState("Super") ||
        event.getModifierState("Win") /* hack for IE */) {
        return;
    }

    // Also ignore if two or more modifiers except Shift are active.
    if (event.getModifierState("Control") +
        event.getModifierState("Alt") +
        event.getModifierState("Meta") > 1) {
        return;
    }

    let el;
    // Handle shortcut key with standard modifier
    if (event.getModifierState("Control") || event.getModifierState("Meta")) {
        switch (event.key.toLowerCase()) {
            case "arrowdown":
                el = hook.el.querySelector("#current-page");
                el.stepUp();
                el.dispatchEvent(new KeyboardEvent("keyup", {'key': 'ArrowUp'}));
                break;
            case "arrowup":
                el = hook.el.querySelector("#current-page");
                el.stepDown();
                el.dispatchEvent(new KeyboardEvent("keyup", {'key': 'ArrowDown'}));
                break;
            case "k":
                event.preventDefault();
                hook.pushEventTo(hook.el, "show-command-palette", null, () => {});
                break;
            case "o":
                event.preventDefault(); 
                hook.el.querySelector("#toolbar-toggle-outline").click();
                break;
            case "s":
                event.preventDefault();
                hook.el.querySelector("#toolbar-toggle-size").click();
                break;

        }
        return;
    }
};

const onOutlineAnimationStart = (e) => {
    if (e.animationName == 'slide-up-keys') {
        e.target.style.height = null;
    }
};

const onOutlineAnimationEnd = (e) => {
    if (e.animationName == 'slide-down-keys') {
        e.target.style.height = 0;
    }

};


exports.Toolbar = {
    events: [],
    mounted() {
        if (isStorageAvailable('localStorage'))  {
            const toolbarStorage = localStorage.getItem(LOCAL_STORAGE_KEY);
            if(toolbarStorage) {
                const bbox = JSON.parse(toolbarStorage);
                this.el.style.top = null; // in case CSS is already applied
                this.el.style.left = null;
                // use right/bottom instead of top/left to allow blocks (e.g. Table of Contents) to slide easily above the toolbar
                this.el.style.right = `${window.innerWidth - bbox.right}px`;
                this.el.style.bottom = `${window.innerHeight - bbox.bottom}px`;
            }
        }
        // We need to do this to prevent flashing of toolbar from original spot to new spot
        this.el.classList.add("fade-in-scale");

        handleDragAndDrop(this.el);

        this.events = [
            [document, 'keydown', handleKeyboardEvent(this)], 
        ];

        const outlineSelector = this.el.querySelector("#toolbar-outline");

        if (outlineSelector) {
            this.events.push(
                [outlineSelector, "animationend", onOutlineAnimationEnd],
                [outlineSelector, "animationstart", onOutlineAnimationStart]
            );
        }

        addEvents(this.events);
    },
    destroyed() {
        removeEvents(this.events);
        this.events = [];
    }
};

