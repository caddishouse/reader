const useState = (initialValue = {}) => {
    let state = initialValue;
    return [
        () => state, // getState
        (newState) => { // setState
            state = {
                ...state,
                ...newState
            }
        }
    ];
};

const initialState = {
    currentPage: 0,
    totalPages: 1,
    pdfViewer: null,
};

const [getState, setState] = useState(initialState);

module.exports = {
    getState,
    setState,
    resetState: () => {
        setState(initialState);
    }
};
