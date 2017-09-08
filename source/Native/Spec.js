/* global F2, F3, HttpMock, requestAnimationFrame, Event */
/* eslint no-unused-vars: ["error", { "varsIgnorePattern": "^_" }] */
/* eslint camelcase: "off" */
/* eslint no-undef: "off" */
/* eslint no-control-regex: "off" */

var _takaczapka$elm_spec$Native_Spec = (function () {
    window.Element.prototype.oldGetBoundingClientRect =
        window.Element.prototype.getBoundingClientRect

    document.oldElementFromPoint = document.elementFromPoint

    document.elementFromPoint = function (x, y) {
        if (window._elmSpecLayout) {
            var element = window._elmSpecLayout
                .filter(function (item) {
                    var rect = item[1]

                    return (
                        rect.top <= y &&
                        rect.top + rect.height >= y &&
                        rect.left <= y &&
                        rect.left + rect.width >= x &&
                        document.querySelector(item[0])
                    )
                })
                .sort(function (aRect, bRect) {
                    return bRect[1].zIndex - aRect[1].zIndex
                })
                .map(function (item) {
                    return document.querySelector(item[0])
                })
                .shift()

            if (element) {
                return element
            }
        }

        return document.oldElementFromPoint(x, y)
    }

    window.Element.prototype.getBoundingClientRect = function () {
        if (window._elmSpecLayout) {
            for (var value of window._elmSpecLayout) {
                var selector = value[0]
                var rect = value[1]
                if (this.matches(selector)) {
                    return rect
                }
            }
        }

        return this.oldGetBoundingClientRect()
    }

    function triggerMouseEvent (node, eventType) {
        var clickEvent = document.createEvent ('MouseEvents');
        clickEvent.initEvent (eventType, true, true);
        node.dispatchEvent (clickEvent);
    }

    var task = _elm_lang$core$Native_Scheduler.nativeBinding
    var succeed = _elm_lang$core$Native_Scheduler.succeed
    var fromArray = _elm_lang$core$Native_List.fromArray
    var toArray = _elm_lang$core$Native_List.toArray
    var tuple0 = _elm_lang$core$Native_Utils.Tuple0
    var nothing = _elm_lang$core$Maybe$Nothing
    var just = _elm_lang$core$Maybe$Just

    var error = function (message) {
        return {ctor: 'Error', _0: message}
    }

    var pass = function (message) {
        return {ctor: 'Pass', _0: message}
    }

    var fail = function (message) {
        return {ctor: 'Fail', _0: message}
    }

    var bold = function (message) {
        return '\x1b[1m' + message + '\x1b[0m'
    }

    var boldString = function (message) {
        return bold('"' + message + '"')
    }

    var withElement = function (selector, method) {
        try {
            var el = document.querySelector(selector)
            if (el) {
                return method(el)
            } else {
                return error('Element not found: ' + bold(selector))
            }
        } catch (e) {
            return error(e.toString())
        }
    }

    var taskWithElement = function (selector, method) {
        return task(function (callback) {
            callback(succeed(withElement(selector, method)))
        })
    }

    var containsText = function (value, selector) {
        return taskWithElement(selector, function (element) {
            if (element.textContent.indexOf(value) >= 0) {
                return pass('Element ' + bold(selector) + ' contains text ' + boldString(value))
            } else {
                return fail('Elements ' + bold(selector) + ' text ' + boldString(element.textContent) + ' does not contain ' + boldString(value))
            }
        })
    }

    var attributeContains = function (attribute, value, selector) {
        return taskWithElement(selector, function (element) {
            var attributeValue = element.getAttribute(attribute) || ''
            if (attributeValue.indexOf(value) >= 0) {
                return pass('Attribute ' + bold(attribute) + ' of element ' + bold(selector) + ' contains text ' + boldString(value))
            } else {
                return fail('Attribute ' + bold(attribute) + ' of element ' + bold(selector) + ' does not contain text ' + boldString(value))
            }
        })
    }

    var attributeEquals = function (attribute, value, selector) {
        return taskWithElement(selector, function (element) {
            var attributeValue = element.getAttribute(attribute) || ''
            if (attributeValue.toString() === value) {
                return pass('Attribute ' + bold(attribute) + ' of element ' + bold(selector) + ' equals ' + boldString(value))
            } else {
                return fail('Attribute ' + bold(attribute) + ' of element ' + bold(selector) + ' does not equal ' + boldString(value))
            }
        })
    }

    var classPresent = function (klass, selector) {
        return taskWithElement(selector, function (element) {
            if (element.classList.contains(klass)) {
                return pass('Element ' + bold(selector) + ' has class ' + bold(klass))
            } else {
                return fail('Element ' + bold(selector) + ' does not have class ' + bold(klass))
            }
        })
    }

    var styleEquals = function (style, value, selector) {
        return taskWithElement(selector, function (element) {
            var val = window.getComputedStyle(element)[style].toString()
            if (val === value) {
                return pass('Element ' + bold(selector) + ' has style ' + bold(style) + ' with value ' + boldString(value))
            } else {
                return fail('Element ' + bold(selector) + ' does not have style ' + bold(style) + ': ' + bold(val) + ' with value ' + boldString(value))
            }
        })
    }

    var inlineStyleEquals = function (style, value, selector) {
        return taskWithElement(selector, function (element) {
            var val = element.style[style].toString()
            if (val === value) {
                return pass('Element ' + bold(selector) + ' has style ' + bold(style) + ' with value ' + boldString(value))
            } else {
                return fail('Element ' + bold(selector) + ' does not have style ' + bold(style) + ': ' + bold(val) + ' with value ' + boldString(value))
            }
        })
    }

    var elementDisabled = function (selector) {
        return task(function (callback) {
            try {
                var el = document.querySelector(selector)
                if (el && el.disabled) {
                    return callback(succeed(pass('Element ' + bold(selector) + ' is disabled')))
                } else {
                    return callback(succeed(fail('Element ' + bold(selector) + ' is not disabled')))
                }
            } catch (e) {
                return callback(succeed(error(e.toString())))
            }
        })
    };

    var elementPresent = function (selector) {
        return task(function (callback) {
            try {
                var el = document.querySelector(selector)
                if (el) {
                    return callback(succeed(pass('Element ' + bold(selector) + ' is present')))
                } else {
                    return callback(succeed(fail('Element ' + bold(selector) + ' is not present')))
                }
            } catch (e) {
                return callback(succeed(error(e.toString())))
            }
        })
    }

    var elementVisible = function (selector) {
        return taskWithElement(selector, function (element) {
            var result = testVisibility(element, selector)
            if (result) {
                return result
            } else {
                return pass('Element ' + bold(selector) + ' should be visible (no CSS used to hide it)')
            }
        })
    }

    var checkboxChecked = function (selector) {
        return task(function (callback) {
            try {
                var el = document.querySelector(selector)
                if (el && el.checked) {
                    return callback(succeed(pass('Element ' + bold(selector) + ' is checked')))
                } else {
                    return callback(succeed(fail('Element ' + bold(selector) + ' is unchecked')))
                }
            } catch (e) {
                return callback(succeed(error(e.toString())))
            }
        })
    };

    var testVisibility = function (element, selector) {
        if (!element) {
            return null
        }
        var style = window.getComputedStyle(element)
        if (style.display === 'none') {
            return fail('Element ' + bold(selector) + ' is hidden by ' + bold('display: none'))
        } else if (parseFloat(style.opacity) === 0) {
            return fail('Element ' + bold(selector) + ' is hidden by ' + bold('opacity: 0'))
        } else if (style.visibility === 'hidden') {
            return fail('Element ' + bold(selector) + ' is hidden by ' + bold('visiblity: hidden'))
        } else if (style.zIndex !== 'auto' && parseInt(style.zIndex) < 0) {
            return fail('Element ' + bold(selector) + ' is hidden by ' + bold('z-index: ' + style.zIndex))
        } else if (testVisibility(element.parentElement, '')) {
            return fail('Element ' + bold(selector) + ' is hidden by parent element.')
        } else {
            return null
        }
    }

    var titleContains = function (text) {
        return task(function (callback) {
            var title = document.title.toString()
            if (title.indexOf(text) >= 0) {
                callback(succeed(pass('Title ' + boldString(title) + ' contains text ' + boldString(text))))
            } else {
                callback(succeed(fail('Title ' + boldString(title) + ' does not contain text ' + boldString(text))))
            }
        })
    }

    var titleEquals = function (text) {
        return task(function (callback) {
            var title = document.title.toString()
            if (title === text) {
                callback(succeed(pass('Title equals ' + boldString(text))))
            } else {
                callback(succeed(fail('Title ' + boldString(title) + ' does not equal ' + boldString(text))))
            }
        })
    }

    var urlContains = function (text) {
        return task(function (callback) {
            var url = window.location.toString()
            if (url.indexOf(text) >= 0) {
                callback(succeed(pass('URL ' + boldString(url) + ' contains text ' + boldString(text))))
            } else {
                callback(succeed(fail('URL ' + boldString(url) + ' does not contain text ' + boldString(text))))
            }
        })
    }

    var bodyContains = function (text) {
        return task(function (callback) {
            var body = document.body.innerHTML
            if (body.indexOf(text) >= 0) {
                callback(succeed(pass('Body ' + boldString(body) + ' contains text ' + boldString(text))))
            } else {
                callback(succeed(fail('Body ' + boldString(body) + ' does not contain text ' + boldString(text))))
            }
        })
    }

    var valueContains = function (text, selector) {
        return taskWithElement(selector, function (element) {
            var value = (element.value || '').toString()
            if (value.indexOf(text) >= 0) {
                return pass('Value ' + boldString(value) + ' of element ' + bold(selector) + ' contains text ' + boldString(text))
            } else {
                return fail('Value ' + boldString(value) + ' of element ' + bold(selector) + ' does not contain text ' + boldString(text))
            }
        })
    }

    var valueEquals = function (text, selector) {
        return taskWithElement(selector, function (element) {
            var value = (element.value || '').toString()
            if (value === text) {
                return pass('Value of element ' + bold(selector) + ' equals ' + boldString(text))
            } else {
                return fail('Value ' + boldString(value) + ' of element ' + bold(selector) + ' does not equal ' + boldString(text))
            }
        })
    }

    var urlEquals = function (text) {
        return task(function (callback) {
            var url = window.location.toString()
            if (url === text) {
                callback(succeed(pass('URL equals ' + boldString(text))))
            } else {
                callback(succeed(fail('URL ' + bold(url) + ' does not equal ' + boldString(text))))
            }
        })
    }

    var logBody = task(function (callback) {
        var body = document.body.innerHTML
        callback(succeed(pass('Body: ' + boldString(body))))
    })

    var getAttribute = function (attribute, selector) {
        return taskWithElement(selector, function (element) {
            return element.getAttribute(attribute)
        })
    }

    var click = function (selector) {
        return taskWithElement(selector, function (element) {
            triggerMouseEvent (element, "mousedown");
            element.click()
            triggerMouseEvent (element, "mouseup");
            return pass('Clicked: ' + bold(selector))
        })
    }

    var invocationCounts = {};

    var unsafeInvocationCount = function (id) {
        return task(function (callback) {
            invocationCounts[id] = invocationCounts[id] ? (invocationCounts[id] + 1) : 1;

            callback(succeed(invocationCounts[id]));
        });
    }

    var setValue = function (value, selector) {
        return taskWithElement(selector, function (element) {
            element.value = value
            return pass('Set value to ' + boldString(value) + ' of ' + bold(selector))
        })
    }

    var setValueAndDispatch = function (value, selector, eventName) {
        return taskWithElement(selector, function (element) {
            element.value = value
            dispatchEventForElement(element, eventName)

            return pass('Set value to ' + boldString(value) + ' of ' + bold(selector) + '; dispatching event ' + boldString(eventName))
        })
    }

    var clearValue = function (selector) {
        return taskWithElement(selector, function (element) {
            element.value = ''
            return pass('Cleared value of ' + bold(selector))
        })
    }

    var clearValueAndDispatch = function (selector, eventName) {
        return taskWithElement(selector, function (element) {
            element.value = ''
            dispatchEventForElement(element, eventName)

            return pass('Cleared value of ' + bold(selector) + '; dispatching event ' + boldString(eventName))
        })
    }

    var dispatchEventForElement = function (element, eventType) {
        var event = new Event('Bubbly Event')
        event.initEvent(eventType, true, true) // TODO
        element.dispatchEvent(event)
    }

    var dispatchEvent = function (eventType, data, selector) {
        var event = new Event(eventType)

        for (var key in data) {
            if (data.hasOwnProperty(key)) {
                event[key] = data[key]
            }
        }

        if (selector === 'document' || selector === 'window') {
            return task(function (callback) {
                if (selector === 'document') {
                    document.dispatchEvent(event)
                    callback(succeed(pass(
                        'Dispatched event ' + bold(eventType) + ' on ' + bold('document')
                    )))
                } else {
                    window.dispatchEvent(event)
                    callback(succeed(pass(
                        'Dispatched event ' + bold(eventType) + ' on ' + bold('window')
                    )))
                }
            })
        } else {
            return taskWithElement(selector, function (element) {
                element.dispatchEvent(event)
                return pass('Dispatched event ' + bold(eventType) + ' on element ' + bold(selector))
            })
        }
    }

    var inputViaPort = function (portName, args) {
        return task(function (callback) {
            try {
                if (window.embeddedApp.ports && window.embeddedApp.ports[portName]) {
                    window.embeddedApp.ports[portName].send(args)
                    return callback(succeed(pass('Port: "' + bold(portName) + '" with payload: ' + bold(JSON.stringify(args)))))
                } else {
                    return callback(succeed(fail('Cannot find port: "' + bold(portName) + '" in the app.')))
                }
            } catch (e) {
                return callback(succeed(error(e.toString())))
            }
        });
    }

    var getTitle = task(function (callback) {
        callback(succeed(document.title.toString()))
    })

    var getBody = task(function (callback) {
        var body = document.body.innerHTML
        callback(succeed(body))
    })

    var getUrl = task(function (callback) {
        callback(succeed(window.location.toString()))
    })

    var raf = function () {
        return task(function (callback) {
            requestAnimationFrame(function () {
                callback(succeed(tuple0))
            })
        })
    }

    var mockResults = {}
    var unhandledResults = {}

    var getTestId = function () {
        if (window._elmSpecTestId) {
            return just(window._elmSpecTestId - 1)
        } else {
            return nothing
        }
    }

    var mockHttpRequests = function (test) {
        var requests = toArray(test.requests)

        if (!mockResults[test.id]) {
            mockResults[test.id] = []
        }
        if (!unhandledResults[test.id]) {
            unhandledResults[test.id] = []
        }

        HttpMock.setup()
        HttpMock.mock(function (request, response) {
          var mock = requests.shift()
          var matching = undefined

          if (mock !== undefined && request.method() === mock.method && request.url() === mock.url) {
            if (request.method() === "POST" || request.method() === "PUT") {
              if (!mock.entity || mock.entity === request.body()) {
                matching = mock;
              }
            } else {
              matching = mock;
            }
          }
          if (matching !== undefined) {
                response.status(mock.response.status)
                response.body(mock.response.body)
                mockResults[test.id].push(mock)
                return response
            } else {
                unhandledResults[test.id].push({
                    method: request.method(),
                    url: request.url(),
                    entity: request._body,
                    response: {status: 200, body: ''}
                })
            }
        })

        return tuple0
    }

    var getMockResults = function (test) {
        return {
            called: fromArray(mockResults[test.id] || []),
            unhandled: fromArray(unhandledResults[test.id] || [])
        }
    }

    var setLayout = function (layout) {
        window._elmSpecLayout =
            toArray(layout).map(function (obj) {
                return [obj._0, obj._1]
            })
    }

    return {
        attributeContains: F3(attributeContains),
        inlineStyleEquals: F3(inlineStyleEquals),
        attributeEquals: F3(attributeEquals),
        mockHttpRequests: mockHttpRequests,
        getMockResults: getMockResults,
        valueContains: F2(valueContains),
        dispatchEvent: F3(dispatchEvent),
        classPresent: F2(classPresent),
        containsText: F2(containsText),
        getAttribute: F2(getAttribute),
        elementPresent: elementPresent,
        elementDisabled: elementDisabled,
        elementVisible: elementVisible,
        checkboxChecked: checkboxChecked,
        titleContains: titleContains,
        styleEquals: F3(styleEquals),
        valueEquals: F2(valueEquals),
        titleEquals: titleEquals,
        urlContains: urlContains,
        bodyContains: bodyContains,
        clearValue: clearValue,
        clearValueAndDispatch: F2(clearValueAndDispatch),
        setValue: F2(setValue),
        setValueAndDispatch: F3(setValueAndDispatch),
        setLayout: setLayout,
        urlEquals: urlEquals,
        getTestId: getTestId,
        getBody: getBody,
        logBody: logBody,
        getTitle: getTitle,
        getUrl: getUrl,
        getBoundingClientRect: function (selector) {
            try {
                return document.querySelector(selector).getBoundingClientRect()
            } catch (e) {
                return {top: 0, left: 0, right: 0, bottom: 0, width: 0, height: 0}
            }
        },
        elementFromPoint: F2(function (x, y) {
            try {
                return just(document.elementFromPoint(x, y).tagName)
            } catch (e) {
                return nothing
            }
        }),
        ansiToHtml: function (value) {
            return value.replace(/\x1b\[1m(.*?)\x1b\[21m/g, '<b>$1</b>')
        },
        report: function (data) {
            if (window._elmSpecReport) {
                window._elmSpecReport(data)
            }
            return task(function () {
                succeed(tuple0)
            })
        },
        click: click,
        inputViaPort: F2(inputViaPort),
        raf: raf(),
        unsafeInvocationCount: unsafeInvocationCount,
    }
}())
