main
	header
		a#title(href="./" title="BanG-Dream Clear Manager") BGDCM
		span(class='{ active: sortType == 0 }' onclick='{ sortClick.bind(this, 0) }') ▼標準
		span(class='{ active: sortType == 1 }' onclick='{ sortClick.bind(this, 1) }') ▼レベル順
		span(class='{ active: sortType == 4 }' onclick='{ sortClick.bind(this, 4) }') ▼クリア状況順
		span(class='{ active: sortType == 2 }' onclick='{ sortClick.bind(this, 2) }') ▼Gr数順
		span(class='{ active: sortType == 5 }' onclick='{ sortClick.bind(this, 5) }') ▼バンド順
		//- URL閲覧時のみBattleソートを追加
		span(class='{ active: sortType == 90 }' onclick='{ sortClick.bind(this, 90) }' if='{URLReadOnly}' ) ▼勝敗順
		
		select#targetDifficults(onchange='{ sortClick }')
			option(data-index=0, value="Easy") Easy
			option(data-index=1, value="Normal") Normal
			option(data-index=2, value="Hard") Hard
			option(data-index=3, value="Expert" selected=true) Expert
			option(data-index=4, value="Special") Special
		div#countShow 
			.diff.clearState_3(title="All Perfect")
			| :{countAP}
			.diff.clearState_2(title="Full Combo")
			| :{countFC}
			.diff.clearState_1(title="Clear")
			| :{countCL}
			.diff.clearState_0(title="No Clear")
			| :{countNC}
		//- 閲覧モード切り替え(URL表示時は非表示にする)
		input#viewOnlyMode(type="checkbox" class='{ hidden: URLReadOnly }' onclick='{ toggleViewOnlyMode }' checked='{ this.URLReadOnly }' disabled='{ this.URLReadOnly }')
		label(for="viewOnlyMode" class='{ hidden: URLReadOnly }' ) 閲覧用モード
		
		
		//- URL生成ボタン(URL表示時は非表示)
		button#sharedData(class='{ hidden: URLReadOnly }' onclick='{ generateDataURL }') URL生成

	div.songLists(class='{wideView: viewOnly}')
		div.song(each='{s in allSongNameList}' class='type_{s.type} band_{s.bandtype}' data-disp='{s.dispValue}' data-index='{s.index}' onclick='{ showEditForm.bind(this, s) }')
			div.name {s.name}
			div.difficults(if='{s.diffs}')
				div.diff(each='{d in s.diffs}' class='diff_{d.diff} clearState_{d.clearState}')
			div.scores(if='{viewOnly}')
				span.score {s.seldiff.perfect}
				span.score {s.seldiff.great}
				span.score {s.seldiff.good}
				span.score {s.seldiff.bad}
				span.score {s.seldiff.miss}
				span.comment {s.seldiff.comment}

	div.editSongData(if='{editSong}' class='type_{editSong.type}')
		div.songname {editSong.name}
		div.latestupdate(if='{editSong.update}') {editSong.update}
		div.tabs(class='tabs_{editSong.diffs.length}')
			div.tab(each='{d,i in editSong.diffs}' class='diff_{d.diff} {active: activeTabIndex == i}' data-index='{i}' onclick='{ showEditFormDiff.bind(this, editSong, d, i) }' ) {d.diff}
		div.scoreform(if='{editSongDiff}')
			label(for="sdPerf") Perfect(自動入力)
			input#sdPerf(type="number" onchange='{ onChangePerfectCounts }' min=0 value="{editSongDiff.perfect}" readonly)
			label(for="sdGret") Great
			input#sdGret(type="number" onchange='{ onChangePerfectCounts }' min=0 value="{editSongDiff.great}" )
			label(for="sdGood") Good
			input#sdGood(type="number" onchange='{ onChangePerfectCounts }' min=0 value="{editSongDiff.good}" )
			label(for="sdBadd") Bad
			input#sdBadd(type="number" onchange='{ onChangePerfectCounts }' min=0 value="{editSongDiff.bad}" )
			label(for="sdMiss") Miss
			input#sdMiss(type="number" onchange='{ onChangePerfectCounts }' min=0 value="{editSongDiff.miss}" )
			br
			label(for="isClear") クリア済
			input#isClear(type="checkbox" checked='{editSongDiff.is_clear}')
			br
			label(for="isFC") フルコンボ済
			input#isFC(type="checkbox" checked='{editSongDiff.is_FC}')
			textarea {editSongDiff.comment}
			button(onclick='{ updateSongDiffScore.bind(this, editSong, editSongDiff) }') 更新
		
	// some dialogs
	virtual(if='{ shortenURL }')
		dialog#shortenCreate(open=true)
			div.closeLink(onclick='{ ()=>{ this.shortenURL = ""; } }') ×
			input.shorturl(type="text" value='{ shortenURL }' readonly=true)
			div.information 共有用のURLを生成しました。
			br
			a(href="https://twitter.com/share?ref_src=twsrc%5Etfw" class="twitter-share-button" data-text="{ sharedText }" data-url="{ shortenURL }" data-hashtags="bgdcm" data-show-count="true") Tweet
	
	footer 
	
	// ---------------------------
	// Style
	style(type="scss").
		@import "../css/main.scss"
		
	// ---------------------------
	// Script
	script.
		var $ = require("jquery");
		var zlib = require("zlib");
		var queryString = require("query-string");
		
		// re-lendering
		var lenderingUpdate = (savedData, sortType) => {
			var selectedDiff = $("#targetDifficults option:selected").val() || "Expert";
			var allSongNameList = global.allSongList
				.filter(e => e.difficult === selectedDiff)
				.map((e,i) => {
					var sd = findSaveDataItem(savedData, e.name, e.difficult);
					var sd_grCount = sd.name ? (sd.great + sd.good + sd.bad + sd.miss) : 9999;
					var sd_msCount = sd.name ? (sd.good + sd.bad + sd.miss) : 9999;
					return {
						name: e.name,
						type: e.type,
						seldiff: {
							explevel: e.level,
							bandtype: e.bandtype,
							totalnotes: e.totalnotes,
							clearState: sd.clearState || 0,
							perfect:	sd.perfect >= 0 ? sd.perfect	: "---",
							great:		sd.great >= 0	? sd.great		: "---",
							good: 		sd.good >= 0	? sd.good		: "---",
							bad:		sd.bad >= 0		? sd.bad		: "---",
							miss: 		sd.miss >= 0	? sd.miss		: "---",
							comment: sd.comment || "",
							grCount: sd_grCount,
							msCount: sd_msCount,
						},
						default_index: e.default,
						index: i,
						diffs: global.allSongList
							.filter(e_ => e_.name === e.name)
							.sort((a,b) => {
								if(a.default < b.default) return -1;
								if(a.default > b.default) return +1;
							})
							.map(e_ => {
								var ssd = findSaveDataItem(savedData, e_.name, e_.difficult);
								var grCount = ssd.great + ssd.good + ssd.bad + ssd.miss;
								var msCount = ssd.good + ssd.bad + ssd.miss;
								return {
									diff: e_.difficult,
									totalnotes: e_.totalnotes,
									clearState: ssd.clearState || 0,
									grCount,
									msCount,
								};
							})
					} 
				});
			// dispValue Set
			allSongNameList.forEach(e => {
				if(sortType == 2){
					if(e.seldiff.grCount > e.seldiff.totalnotes){
						e.dispValue = "---";
					}
					else if(e.seldiff.grCount <= 0){
						e.dispValue = "AP";
					}
					else {
						e.dispValue = e.seldiff.grCount;
					}
				}
				else if(sortType == 3){ e.dispValue = e.seldiff.totalnotes }
				else if(sortType == 4) {
					var d = ["NC", "CL", "FC", "AP"];
					e.dispValue = d[e.seldiff.clearState || 0];
				}
				else if (sortType == 5) {
					e.dispValue = e.seldiff.explevel
					e.bandtype = e.seldiff.bandtype
				}
				else {
					e.dispValue = e.seldiff.explevel
				}
			});
			
			allSongNameList.sort((a,b) => {
				if(sortType == 2){
					// 昇順 ただしAPはNCの手前に表示
					var ac = a.seldiff.grCount || 8888;
					var bc = b.seldiff.grCount || 8888;
					if (ac < bc) return -1;
					if (ac > bc) return +1;
				}
				if(sortType == 3) {
					// 降順
					if (a.seldiff.totalnotes < b.seldiff.totalnotes) return +1;
					if (a.seldiff.totalnotes > b.seldiff.totalnotes) return -1;
				}
				if (sortType == 4) {
					// 降順
					if (a.seldiff.clearState < b.seldiff.clearState) return +1;
					if (a.seldiff.clearState > b.seldiff.clearState) return -1;
				}
				if (sortType == 5) {
					// 昇順
					if (a.bandtype < b.bandtype) return -1;
					if (a.bandtype > b.bandtype) return +1;
				}
				if (sortType >= 1) {
					// 降順
					if (a.seldiff.explevel < b.seldiff.explevel) return +1;
					if (a.seldiff.explevel > b.seldiff.explevel) return -1;
				}
				if(a.default_index > b.default_index) return 1;
				if(a.default_index < b.default_index) return -1;
			})
			
			this.allSongNameList = global.allSongNameList = allSongNameList;
			this.countAP = allSongNameList.filter(e => e.seldiff.clearState == 3).length;
			this.countFC = allSongNameList.filter(e => e.seldiff.clearState == 2).length;
			this.countCL = allSongNameList.filter(e => e.seldiff.clearState == 1).length;
			this.countNC = allSongNameList.filter(e => e.seldiff.clearState == 0).length;
		}
		
		// on Loading Action
		(async () => {
			// songlist get
			global.allSongList = require("../data/songdata.json");
			var savedData = getSaveData();
			
			// if contain query
			var parsed = queryString.parse(location.search);
			if(parsed){
				if(parsed.hash){
					var long = await extractLongURL(parsed.hash);
					console.log(long);
					if(!long || long.data === [] || !long.data.expand[0]){
						alert("parse error.");
						return;
					}
					var long_url = long.data.expand[0].long_url;
					var reg = /http.*\?data=(.+)/
					var sdata_str = decompressStr( long_url.match(reg)[1] );
					var sdata = JSON.parse(sdata_str);
					var restoreData = restoreSaveDataFromShorten(sdata);
					// set readonly mode
					this.URLReadOnly = true;
					this.viewOnly = true;
					global.queryLoadData = savedData = restoreData;
				}
				if(parsed.data){
					// set readonly mode
					this.URLReadOnly = true;
					this.viewOnly = true;
					global.queryLoadData = savedData = JSON.parse(decompressStr(parsed.data)) || [];
				}
			}
			
			// Update
			global.sortType = this.URLReadOnly ? 4 : 0;
			lenderingUpdate(savedData, global.sortType);
		
			this.update();
		})(); 
		
		// extractSeledDiffData
		function extractSeledDiffData(song, diff) {
			// load savedata
			var sd = getSaveData();
			var ssd = findSaveDataItem(sd, song.name, diff);
			var totalnotes = song.diffs.find(e => e.diff === diff).totalnotes;
			var df = {
				diff,
				perfect: ssd.perfect || totalnotes,
				great: ssd.great || 0,
				good: ssd.good || 0,
				bad: ssd.bad || 0,
				miss: ssd.miss || 0,
				comment: ssd.comment || "",
				is_clear: ssd.clearState >= 1,
				is_FC: ssd.clearState >= 2,
			}
			global.totalnotes = totalnotes;
			return df;
		}
		
		// 
		showEditForm(song) {
			$(`.song`).removeClass("active");
			$(`.song[data-index=${song.index}]`).addClass("active");
			
			if(!this.viewOnly){
				this.editSong = song;
				
				// load selected diff
				var seled = $("#targetDifficults option:selected");
				var selectedDiff = seled.val() || "Expert";
				var selectedIndex = seled.data("index");
				this.activeTabIndex = selectedIndex >= 0 ? selectedIndex : 3;
				this.editSongDiff = extractSeledDiffData(song, selectedDiff);
			}
		}
		
		// show edit
		showEditFormDiff(song, diff, i) {
			this.activeTabIndex = i;
			// load savedata
			this.editSongDiff = extractSeledDiffData(song, diff.diff);
		}
		
		// update songdata
		updateSongDiffScore(song, diff) {
			var t = global.totalnotes;
			var gr = $("#sdGret").val() - 0;
			var gd = $("#sdGood").val() - 0;
			var bd = $("#sdBadd").val() - 0;
			var ms = $("#sdMiss").val() - 0;
			var pf = t - gr - gd - bd - ms;
			var cm = $(".scoreform textarea").val();
			var isC = $("#isClear").prop("checked");
			var isF = $("#isFC").prop("checked");
			
			var missCountZero = (gd + bd + ms <= 0);
			var simpleAliveCount = (bd * 50 + ms * 100 < 1000);
			var clearState = (pf === t) ? 3 : (isF || missCountZero) ? 2 : (isC || simpleAliveCount) ? 1 : 0;
			
			var name = song.name;
			var difficult = diff.diff;
			var si = {
				name,
				difficult,
				perfect: pf,
				great: gr,
				good: gd,
				bad: bd,
				miss: ms,
				comment: cm,
				clearState
			}
			setSaveItem(si, name, difficult);
			
			lenderingUpdate(getSaveData(), global.sortType || 0);
		}
		
		// 
		onChangePerfectCounts() {
			var t = global.totalnotes;
			var gr = $("#sdGret").val() - 0;
			var gd = $("#sdGood").val() - 0;
			var bd = $("#sdBadd").val() - 0;
			var ms = $("#sdMiss").val() - 0;
			var pf = t - gr - gd - bd - ms;
			$("#sdPerf").val(pf);
		}
		
		// sort Songlist
		sortClick(type) {
			if(type >= 0){
				this.sortType = global.sortType = type;
			}
			lenderingUpdate(getSaveData(), global.sortType);
		}
		
		toggleViewOnlyMode() {
			if(this.viewOnly = $("#viewOnlyMode").prop("checked")){
				this.editSong = null;
				this.editSongDiff = null;
			}
		}
		
		async generateDataURL() {
			var sd = createShortDataFromSavedData();
			var q = compressStr(JSON.stringify(sd));
			var l = `http://example.com/?data=${q}`;
			var shorten = await generateShortenURL(l);
			
			if(shorten.status_code == 500){
				console.log(shorten);
				alert(`URL生成に失敗しました…… [${shorten.status_txt}]`);
			}
			//history.replaceState(null, null, `?hash=${shorten.data.hash}`)
			var url = `${window.location.origin}${window.location.pathname}?hash=${shorten.data.hash}`;
			var shared = `バンドリのクリア状況を共有！ (AP:${this.countAP}/FC:${this.countFC}/CL:${this.countCL}/NC:${this.countNC})`;
			
			// openDialog
			this.sharedText = shared;
			this.shortenURL = url;
			
			
			this.update();
			if ("twttr" in window) {
				window.twttr.widgets.load();
			}
			
			console.log(this);
			
		}
		
		// get localstrage saved score
		function getSaveData() {
			// if readonly mode
			if(!!global.queryLoadData){
				return global.queryLoadData;
			}
			// localstrage data get
			var lst = localStorage.getItem("savedScore");
			return JSON.parse(lst || "[]");
		}
		function setSaveData(sd){
			// if readonly mode, no action
			if (!!global.queryLoadData) {
				return;
			}
			// localstrage data get
			localStorage.setItem("savedScore", JSON.stringify(sd));
		}
		
		function setSaveItem(si, songName, songDiff){
			// if readonly mode, no action
			if (!!global.queryLoadData) {
				return;
			}
			var sd = getSaveData();
			var i = findSaveDataIndex(sd, songName, songDiff);
			if(i >= 0){
				sd = sd.filter((e,i_) => i_ !== i);
			}
			sd.push(si);
			setSaveData(sd);
		}
		
		// find savedata getItem
		function findSaveDataItem(sd, songName, songDiff){
			if(!sd){ return {}; }
			return sd.find(e => e.name === songName && e.difficult === songDiff) || {};
		}
		function findSaveDataIndex(sd, songName, songDiff){
			if(!sd){ return {}; }
			var elm = findSaveDataItem(sd, songName, songDiff);
			return sd.indexOf(elm);
		}
		
		
		// compress/decompress
		function compressStr(str){
			var cms = zlib.gzipSync(str);
			return encodeURIComponent( new Buffer(cms).toString("base64") );
		}
		function decompressStr(str){
			var b64s = new Buffer(decodeURIComponent(str), "base64");
			return zlib.unzipSync(b64s);
		}
		
		// create shorten data from saved big data
		function createShortDataFromSavedData(){
			var sd = getSaveData();
			var rst = {};
			sd.forEach(e => {
				var songd = global.allSongList.find(e_ => e_.name === e.name && e_.difficult === e.difficult);
				if(songd){
					rst[songd.id] = [
						e.clearState,
						e.great || "",
						e.good || "",
						e.bad || "",
						e.miss || ""
					].join("|");
				}
			});
			return rst;
		}
		
		// restore big data from shorten data
		function restoreSaveDataFromShorten(shd){
			var rst = [];
			Object.keys(shd).forEach(k => {
				var v = shd[k];
				var [clearState, great, good, bad, miss] = v.split("|");
				var s = global.allSongList.find(e => e.id == Number(k));
				rst.push({
					name: s.name,
					difficult: s.difficult,
					perfect: (s.totalnotes - great - good - bad - miss),
					great: great - 0,
					good: good - 0,
					bad: bad - 0,
					miss: miss - 0,
					comment: "",
					clearState: clearState - 0,
				});
			});
			return rst;
		}
		
		// create shorten URL
		async function generateShortenURL(base_url){
			var url = `https://api-ssl.bitly.com/v3/shorten?access_token=${process.env.BITLY_ACCESS_TOKEN}&longUrl=${base_url}`;
			return await $.ajax({
				url,
				dataType: "jsonp",
			});
		}
		
		// extract shorten hash to Long url
		async function extractLongURL(hash){
			var url = `https://api-ssl.bitly.com/v3/expand?access_token=${process.env.BITLY_ACCESS_TOKEN}&hash=${hash}`;
			return await $.ajax({
				url,
				dataType: "jsonp",
			});
		}
		
		function execCopy(string){
			var temp = document.createElement('div');
			temp.appendChild(document.createElement('pre')).textContent = string;
			
			var s = temp.style;
			s.position = 'fixed';
			s.left = '-100%';
			
			document.body.appendChild(temp);
			document.getSelection().selectAllChildren(temp);
			
			var result = document.execCommand('copy');
			document.body.removeChild(temp);
			// true なら実行できている falseなら失敗か対応していないか
			return result;
		}
