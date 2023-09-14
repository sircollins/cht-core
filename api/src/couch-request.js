const request = require('request-promise-native');
const environment = require('./environment');

function isPlainObject(value) {
    if (typeof value !== 'object' || value == null) {
        return false;
    }
    const prototype = Object.getPrototypeOf(value);
    return (prototype === null || prototype === Object.prototype || Object.getPrototypeOf(prototype) === null) && !(Symbol.toStringTag in value) && !(Symbol.iterator in value);
}

function globalCouchRequestOptions() {
    return {
        servername: environment.host
    };
}

module.exports = {
    get: (options = {}) => {
        if (isPlainObject(options) === false) {
            return Promise.reject(Error('"options" must be a plain object'));
        }
        return request.get({
            ...globalCouchRequestOptions(), ...options
        });
    },
    post: (options = {}) => {
        if (isPlainObject(options) === false) {
            return Promise.reject(Error('"options" must be a plain object'));
        }
        return request.post({ ...globalCouchRequestOptions(), ...options });
    },
    put: (options = {}) => {
        if (isPlainObject(options) === false) {
            return Promise.reject(Error('"options" must be a plain object'));
        }
        return request.put({ ...globalCouchRequestOptions(), ...options });
    },
    delete: (options = {}) => {
        if (isPlainObject(options) === false) {
            return Promise.reject(Error('"options" must be a plain object'));
        }
        return request.delete({ ...globalCouchRequestOptions(), ...options });
    },
    head: (options = {}) => {
        if (isPlainObject(options) === false) {
            return Promise.reject(Error('"options" must be a plain object'));
        }
        return request.head({ ...globalCouchRequestOptions(), ...options });
    },

}