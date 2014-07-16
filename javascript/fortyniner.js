    $(document).ready(new function () {

        try {

            window.onkeydown = keyHandler;
        }
        catch (e) {
            alert("<p>ready: " + e + "</p>");
        }
    });

    function keyHandler(event) {
        try {
            alert("<p>keyHandler: " + event.keyCode + "</p>");

        }
        catch (e) {
            alert("<p>keyHandler: " + e + "</p>");
        }

    }

