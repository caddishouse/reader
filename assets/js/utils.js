module.exports = {
    addEvents(events) {
        events.map(([element, key, callback]) => {
            element.addEventListener(key, callback);
        });

    },
    removeEvents(events) {
        events.map(([element, key, callback]) => {
            element.removeEventListener(key, callback);
        });
        // While it's possible to clear the events array here
        // it's preferred to not mutate an array so opaquely
    },
    binarySearch(sortedArray, key, getValueFn) {
        let start = 0;
        let end = sortedArray.length - 1;

        while (start <= end) {
            let middle = Math.floor((start + end) / 2);

            if (testerFn(sortedArray[middle], key)) {
                return sortedArray[middle]
            } else if (sortedArray[middle] < key) {
                start = middle + 1;
            } else {
                end = middle - 1;
            }
        }
        // Middle at this point will be either 0 or end.
        return sortedArray[middle];
    }
};
