/*
 * Originally adapted from:
 * https://github.com/fly-apps/live_beats/blob/6b02cfc614aaf1f7a5ebc595c435bf62a65f5bcb/assets/js/app.js#L16
 *
 *
 # MIT License

 * Copyright (c) 2022 Fly.io
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

exports.Flash = {
    mounted(){
        let duration = this.el.dataset.duration;
        const hide = () => this.el.click()
        if (duration) {
            duration = parseInt(duration, 10);
            this.timer = setTimeout(() => hide(), duration)
            this.el.addEventListener("phx:hide-start", () => clearTimeout(this.timer))
            this.el.addEventListener("mouseover", () => {
                clearTimeout(this.timer)
                this.timer = setTimeout(() => hide(), duration)
            })
        }
  },
  destroyed(){ clearTimeout(this.timer) }
};
