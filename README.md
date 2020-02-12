# The Storage Access API

A [Work Item](https://privacycg.github.io/charter.html#work-items) of
the [Privacy Community Group](https://privacycg.github.io/).

## Authors:

- John Wilander

## Participate
- https://github.com/privacycg/storage-access/issues

## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Introduction](#introduction)
- [Motivating Use Cases](#motivating-use-cases)
- [Non-goals](#non-goals)
- [The API](#the-api)
  - [hasStorageAccess](#hasstorageaccess)
  - [requestStorageAccess](#requeststorageaccess)
- [Key Scenarios](#key-scenarios)
  - [Recovery Path](#recovery-path)
  - [Timeout of an Opt In](#timeout-of-an-opt-in)
- [Detailed Design Discussion](#detailed-design-discussion)
  - [Automatically Grant Access to Websites Used Often](#automatically-grant-access-to-websites-used-often)
  - [Automatically Grant Access Upon User Interaction](#automatically-grant-access-upon-user-interaction)
- [Considered Alternatives](#considered-alternatives)
  - [[Alternative 1]](#alternative-1)
  - [[Alternative 2]](#alternative-2)
- [Stakeholder Feedback / Opposition](#stakeholder-feedback--opposition)
- [References & Acknowledgements](#references--acknowledgements)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

Browsers may block third-party resources from accessing cookies and other storage for privacy and security reasons. The
most popular reason is cross-site tracking prevention. Such blocking breaks authenticated cross-site embeds such as
commenting widgets, embedded payment providers, and subscribed video services.

The Storage Access API provides a means for authenticated cross-site embeds to check their blocking status and request
access to storage if they are blocked.

## Motivating Use Cases

These use cases assume that the third-party is blocked from cookie access and possibly other storage too.

### Social Network Commenting Widget
The user is logged in to Social Network Example with domain name social.example and is now visiting blog.example which
allows readers to comment on blogposts using their social.example account. The user taps/clicks in the commenting
widget, a cross-site iframe from social.example, to make a comment. The onclick event handler in the iframe calls the
Storage Access API to request cookie access needed to authenticate the user cross-site. The user has not commented on
this blog before and thus gets prompted to allow or disallow storage access, decides to allow storage access, and
proceeds to comment on the blogpost.

### Third-Party Payment Provider
The user is logged in to Payments Example with domain name payments.example and is now shopping on clothes.example. They
decide to check out and pick Payments Example as their preferred way of paying. The Payments Example option is served
through a cross-site iframe from payments.example that calls the Storage Access API upon the tap/click to pick it as
payment option. The user has used Payments Example previously on this shopping site and thus already been prompted for
storage access. Therefore, the user is not prompted again, the iframe is automatically granted storage access, and
the user proceeds to fulfill the payment.

### Subscribed Video Service
The user is logged in to Online Videos Example with domain name videos.example and is paying for an ad-free video
experience. Now they are on games.example and want to watch a video of an exciting game play. The video is served in a
cross-site iframe from videos.example and the iframe calls the Storage Access API upon the tap/click on its play button.
The user has used Online Videos previously on this gaming site and thus is not prompted, the iframe is automatically
granted storage access, and the user proceeds to watch the video.

## Non-Goals

The Storage Access API is not intended to grant arbitrary third-parties cookie access. It is only intended to grant
cookie access to third parties that the user actively uses as first party too, i.e. websites the user recognizes and
uses.

The Storage Access API can be used for many more things than authenticated embeds, for instance single sign-on, 
cross-site subscription services, and federated logins. However, those are not the primary goals of this API and thus,
requirements that are serving those use cases but not the authenticated embed use case might not be met by the
Storage Access API. That said, the Storage Access API is not in conflict with single sign-on, cross-site subscription
services, and federated logins.

## The API

The Storage Access API lives under the document object since it controls document.cookie and the scope of the storage
access may be tied to the scope of the document.

### hasStorageAccess

```js
var promise = document.hasStorageAccess();
promise.then(
  function (hasAccess) {
    // Boolean hasAccess says whether the document has access or not.
  },
  function (reason) {
    // Promise was rejected for some reason.
  }
);
```

### requestStorageAccess

```html
<script>
function makeRequestWithUserGesture() {
  var promise = document.requestStorageAccess();
  promise.then(
    function () {
      // Storage access was granted.
    },
    function () {
      // Storage access was denied.
    }
  );
}
</script>
<button onclick="makeRequestWithUserGesture()">Play video</button>
```

## Key scenarios

### The User Is Not Yet Logged In To the Embedee

In the case of the user not being logged in to the embeddee, there it should be possible for the iframe to make use of
the user gesture that was required to call document.requestStorageAccess() to also do a popup to enable the user to log
in.

### The User Opts Out

In the case of the user being prompted for storage access and explicitly opts out, the requesting iframe should not be
able to prompt again or do a popup without receiving another user gesture.

## Detailed Design Discussion

### Recovery Path

If the user explicitly opts out when prompted for storage access, they may find themselves in a situation they don't
like or didn't expect, such as no ability to comment on a blogpost or ads in a video feed from a service they pay for to
be ad-free. In short, there needs to be a recovery path.

One way of dealing with this is to allow at least two prompts per embed. If the user explicitly opts out twice, it's a
done deal.

Another way of dealing with this is to offer affordances to reset choices in browser settings.

### Timeout of an Opt In

If the user explicitly grants storage access to an embedee, the question is for how long that grant should last before a
new prompt is shown? Options include 1) as long as the user keeps re-engaging with the embedee on an
hourly/daily/weekly/monthly basis, 2) with a static timeout of e.g. 30 days, or 3) only for the lifetime of the embedded
document.

## Considered Alternatives

There are some possible alternatives.

### Automatically Grant Access to Websites Used Often

Instead of requiring an explicit API call, the browser could keep track of which websites the user engages with a lot,
possibly even know which websites the user is logged in to, and grant storage access to those websites automatically.

However, it may be undesirable to allow global cross-site authentication by a third party based on activity on a
first-party website. In fact, such blanket cross-site authentication/identification is often what blocking of
third-party cookies and storage is trying to avoid.

### Automatically Grant Access Upon User Interaction

Instead of requiring an explicit API call, the browser could grant storage access to embedded third-party iframes upon
user interaction with the iframe. This allows for blocking of third-party cookies in all passive scenarios such as
pure page loads and scrolling.

However, such behavior may incentivize third-parties to render iframes solely for the purposes of getting cookie access,
for instance through invisible overlay iframes à la Clickjacking or through iframes that look like first-party content.

## Stakeholder Feedback / Opposition

- Safari : Shipping
- Firefox : Shipping
- Edge : Positive
- Chrome : No public signal

## References & Acknowledgements

Several people have provided valuable feedback already in the
[WHATWG HTML issue](https://github.com/whatwg/html/issues/3338) filed on Jan 10, 2018. We're thankful for all that
engagement.
