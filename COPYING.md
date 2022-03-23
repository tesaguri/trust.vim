# trust.vim

Copyright (c) 2022 Daiki "tesaguri" Mizukami

`trust.vim` is primarily licensed under either of:

- The Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>), or
- The MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)

at your option.

Additionally, the project contains following thirdparty code with different license terms:

## vital-Whisky

Code under `autoload/vital/_trust/System/Job/` and `autoload/vital/_trust/System/Job.vim` is taken
from [vital-Whisky]. License terms of vital-Whisky follow:

```text
The MIT License (MIT)

Copyright (c) since 2016 Alisue, hashnote.net

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

[vital-Whisky]: <https://github.com/lambdalisue/vital-Whisky>

## vital.vim

Other code under `autoload/vital/` is taken from [vital.vim]. vital.vim is _licensed_ under [NYSL]:

```text
NYSL Version 0.9982

A. 本ソフトウェアは Everyone'sWare です。このソフトを手にした一人一人が、
   ご自分の作ったものを扱うのと同じように、自由に利用することが出来ます。

  A-1. フリーウェアです。作者からは使用料等を要求しません。
  A-2. 有料無料や媒体の如何を問わず、自由に転載・再配布できます。
  A-3. いかなる種類の 改変・他プログラムでの利用 を行っても構いません。
  A-4. 変更したものや部分的に使用したものは、あなたのものになります。
       公開する場合は、あなたの名前の下で行って下さい。

B. このソフトを利用することによって生じた損害等について、作者は
   責任を負わないものとします。各自の責任においてご利用下さい。

C. 著作者人格権は ○○○○ に帰属します。著作権は放棄します。

D. 以上の３項は、ソース・実行バイナリの双方に適用されます。

このライセンス文書自体は CC0 の下で公開されています。
```

(Citation note: [CC0] is a hyperlink)

```text
NYSL Version 0.9982 in English (unofficial)

A. This software is "Everyone'sWare". It means:
  Anybody who has this software can use it as if he/she is
  the author.

  A-1. Freeware. No fee is required.
  A-2. You can freely redistribute this software.
  A-3. You can freely modify this software. And the source
      may be used in any software with no limitation.
  A-4. When you release a modified version to public, you
      must publish it with your name.

B. The author is not responsible for any kind of damages or loss
  while using or misusing this software, which is distributed
  "AS IS". No warranty of any kind is expressed or implied.
  You use AT YOUR OWN RISK.

C. Copyrighted to (.......)

D. Above three clauses are applied both to source and binary
  form of this software.
```

The above copies of the _license_ was retrieved on 2022-03-23. Note that, as of this writing, the
original distribution of vital.vim only links to the website of NYSL and does not include a copy of
the license with it. Therefore, the version of NYSL the authors intended to use is unknown. Also,
the placeholder for author name in the license terms (`(.......)`) is left intact in the above
copies.

Although the English translation seems to have failed to convey it, article C. of the _license_
declares waiver of copyright. Therefore you can think of it as a kind of public domain dedication
under certain legislations, even though it calls itself a _license_ (disclaimer: I am not a lawyer
and this is not to be interpreted as a legal advice).

[vital.vim]: <https://github.com/vim-jp/vital.vim>
[NYSL]: <http://www.kmonos.net/nysl/index.en.html>
[CC0]: <https://creativecommons.org/publicdomain/zero/1.0/>

## `gen_vimdoc.py`

`vendor/gen_vimdoc.py` is retrieved from `scripts/` in <https://github.com/neovim/neovim.git>.

Copyright Neovim contributors. All rights reserved.

The file is licensed under the terms of the Apache 2.0 license ([LICENSE-APACHE](LICENSE-APACHE)).

## `lua2dox_lua`

`vendor/lua2dox.lua` and `vendor/lua2dox_filter` are retrieved from `scripts/` in
<https://github.com/neovim/neovim.git>.

Documentation of the very original version is available at <http://tug.ctan.org/web/lua2dox/>.

See each file for copyright notices and license information.
