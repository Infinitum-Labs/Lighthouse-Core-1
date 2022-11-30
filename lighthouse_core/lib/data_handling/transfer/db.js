import { ok, notFound, serverError, badRequest, created, forbidden, response } from 'wix-http-functions';
import wixData from 'wix-data';
import { getSecret } from 'wix-secrets-backend';

// https://infinitumlabsinc.editorx.io/lighthousecloud/_functions/getById

const options = {
    "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Authorization": null
    },
    "body": {
        "status": {
            "code": 500,
            "msg": "Default response"
        },
        "payload": {}
    }
};

export function get_getJwtToken(request) {
    var res = options;

    wixData.query("Users")
        .contains("emailAddress", request.query.emailAddress)
        // .contains("password", request.query.password) // to detect incorrect password
        .find()
        .then((result) => {
            if (result.items.length == 0) {
                res.body.status.code = 404;
                res.body.status.msg = "No users with that email address";
            } else {
                var item = result.items[0];
                if (request.query.password == item['password']) {
                    res.body.status.code = 200;
                    res.body.status.msg = "OK";
                    res.headers.Authorization = "authed";
                } else {
                    res.body.status.code = 403;
                    res.body.status.msg = "Incorrect password";
                }
            }
        }).catch((err) => {
            console.log(err);
            res.body.status.code = 500;
            res.body.status.msg = err;
        });

    res.status = res.body.status.code;
    return response(res);
}

export function get_getById(request) {
    var res = options;

    wixData.query(request.query.collectionId).find()
        .then((result) => {
            if (result.items.length == 0) {
                res.body.status.code = 404;
                res.body.status.msg = "No items in collection with a matching ID.";
            } else {
                res.body.status.code = 200;
                res.body.status.msg = "OK";
                res.body.payload = result.items.find(e => e['objectId'] == request.query.objectId);
            }
        }).catch((err) => {
            console.log(err);
            res.body.status.code = 500;
            res.body.status.msg = err;
        });

    res.status = res.body.status.code;
    return response(res);
}