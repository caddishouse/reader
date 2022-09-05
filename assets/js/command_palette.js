const KEY_DOWN_ARROW = 40;
const KEY_UP_ARROW = 38;
const KEY_ENTER = 13;

class CommandPalette {
    constructor(el) {
        this.el = el;
        this.results = [];
        this.selectionIndex = -1;

        document.addEventListener("keydown", this.handleKeyDown);

    }

    destructor() {
        document.removeEventListener("keydown", this.handleKeyDown);
    }

    handleKeyDown = (event) => {
        if (event.isComposing || event.keyCode === 229) {
            return;
        }
        switch (event.key) {
                /*
            case "Escape":
                event.preventDefault();
                this.close();
                break;
                */
            case "ArrowDown":
                event.preventDefault();
                this.moveDown();
                break;
            case "ArrowUp":
                event.preventDefault();
                this.moveUp();
                break;
            case "Enter":
                event.preventDefault();
                if (this.selectionIndex >= 0) {
                    this.results[this.selectionIndex].querySelector("a").click();
                }
                break;
        }
    }

    getSelectedResult() {
        return {
            id: this.results[this.selectionIndex].dataset.resultId,
            source: this.results[this.selectionIndex].dataset.resultSource,
            name: this.results[this.selectionIndex].dataset.resultName,
        }
    }

    updateResults() {
        this.results = this.el.querySelectorAll("li[data-result-id]");
        this.selectionIndex = -1;
    }

    moveDown() {
        if(this.selectionIndex < this.results.length - 1) {
            if (this.selectionIndex >= 0) {
                this.results[this.selectionIndex].classList.remove("active");
            }
            this.results[this.selectionIndex + 1].classList.add("active");
            this.selectionIndex += 1;
        }
    }

    moveUp() {
        if(this.selectionIndex > 0) {
            this.results[this.selectionIndex].classList.remove("active");
            this.results[this.selectionIndex - 1].classList.add("active");
            this.selectionIndex -= 1;
        }
    }
}

exports.CommandPalette = {
    mounted() {
        this.instance = new CommandPalette(this.el);
    },
    updated() {
        this.instance.updateResults();
    },
    destroyed() {
        this.instance.destructor();
    }

};

