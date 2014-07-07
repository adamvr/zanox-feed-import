/**
 * Module dependencies
 */
var expat = require('node-expat')
  , stream = require('stream')
  , debug = require('debug')('zanox-stream')
  , util = require('util');

var ZanoxStream = module.exports = function ZanoxStream (opts) {
  var parser = this.parser = new expat.Parser('UTF-8')
    , that = this;

  // Grab options
  this.opts = opts || {};

  // Set starting state
  this.state = 'none';

  // Setup parser events
  parser.on('startElement', function (name, attrs) {
    debug('start state: %s, key: %s', that.state, name);
    if (that.state === 'none' && name === 'product') {
      that.state = 'product';
      that.obj = {};
    } else if (that.state === 'product') {
      that.state = 'key';
      that.key = name;
      that.val = '';
    }
  }).on('text', function (text) {
    debug('text state: %s, text: %s', that.state, text);
    if (that.state === 'key') {
      that.val += text;
    }
  }).on('endElement', function (name) {
    debug('end state: %s, key: %s', that.state, name);
    if (that.state === 'product') {
      that.state = 'none';
      that.push(JSON.stringify(that.obj) + (that.opts.newlines ? '\n' : ''));
    } else if (that.state === 'key') {
      that.state = 'product';
      if (that.opts.rename[that.key]) that.key = that.opts.rename[that.key];
      if (!~that.opts.blacklist.indexOf(that.key)) {
        that.obj[that.key] = that.opts.trim ? that.val.trim() : that.val;
      }
    }
  });
  
  // Inherit from parent
  stream.Duplex.call(this, opts);
};
util.inherits(ZanoxStream, stream.Duplex);

ZanoxStream.prototype._write = function (chunk, encoding, done) {
  this.parser.write(chunk);
  done();
};

ZanoxStream.prototype._read = function (size) {
  return;
};

if (require.main === module) {
  process.stdin
    .pipe(new ZanoxStream({
      newlines: true,
      trim: true,
      rename: {
        name: 'product_name'
      },
      blacklist: ['description']
    }))
    .pipe(process.stdout);
}
