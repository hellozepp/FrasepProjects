    // Create a function which requires a username and a password
    function getToken(user, password) {
        // Define a constant which contains the authentication information.
        // Username and password will be assigned from the parameters passed to the function
        const data = {
            "grant_type": "password",
            "username": user,
            "password": password
        };

        // Define a constant which contains the headers information for the HTTP request.
        // The Authorization header is defined using Basic authentication.
        // The value is a base64 encoded value created from the client application and client secret.
        const headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'Authorization': "Basic " + btoa("frasepapp:frasepsecret")
        };

        // Returns a Promise in order to execute the authentication asynchronously
        return new Promise((resolve, reject) => {
            // Call the REST API using a POST method and pass the defined constants: data and headers
            $.ajax({
                url: "https://frasepviya35smp.cloud.com/SASLogon/oauth/token",
                type: "POST",
                headers: headers,
                data: data
            }).then(response => {
                // Resolve the promise
                resolve(response);
            });
        });
    };

    function getSession(token) {
        // Define a constant which contains the headers information for the HTTP request.
        const headers = {
            'Authorization': "Bearer " + token
        };

        // Returns a Promise in order to execute the authentication asynchronously
        return new Promise((resolve, reject) => {
            // Call the REST API using a POST method and pass the defined constants: data and headers
            $.ajax({
                url: "https://frasepviya35smp.cloud.com/cas-shared-default-http/cas/sessions",
                type: "POST",
                headers: headers
            }).then(response => resolve(response));
        });
    };

    function callCAS (baseURL, action, token, session, data){
        // The HTTP header object that will be passed to the request.
        const headers = {
            "authorization": 'bearer ' + token,
            "accept" : "application/json",
            "content-type": "application/json"
        }
        const endpoint = "/cas-shared-default-http/cas/sessions/"+session+"/actions/"+action;

         // Create the URL for the REST API endpoint
        const url = baseURL + endpoint;

        return new Promise((resolve, reject) => {
            $.ajax({
                url: url,
                type: "POST",
                headers : headers,
                data : JSON.stringify(data)
            }).then(response => resolve(response));
        });
    }

    function displayData (headers, rows) {
        let html = "<table>";
        html += '<thead><tr>';
        for (header in headers) {
            html += "<th>" + headers[header]["name"]+ "</th>"
        }
        html += "</tr></thead>";
        html += '<tbody>';

        for (row in rows){
            html += "<tr>";
            for (cell in rows[row]){
                html += "<td>" +rows[row][cell] + "</td>"
            }
            html += "</tr>";
        }
        html += "</tbody>";
        html += "</table>";
        return html;
    }