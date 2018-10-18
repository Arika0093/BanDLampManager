main
	header
	div.sortButtons
		span(onclick='{ sortClick.bind(this, 0) }') ▼標準
		span(onclick='{ sortClick.bind(this, 1) }') ▼EXレベル順
	div.songLists
		div.song(each='{s in allSongNameList}' class='type_{s.type}' data-index='{s.index}' onclick='{ showEditForm.bind(this, s) }')
			div.name {s.name}
			div.difficults(if='{s.diffs}')
				div.diff(each='{d in s.diffs}' class='diff_{d.diff} clearState_{d.clearState}')
			
	div.editSongData(if='{editSong}' class='type_{editSong.type}')
		div.songname {editSong.name}
		div.latestupdate(if='{editSong.update}') {editSong.update}
		div.tabs(class='tabs_{editSong.diffs.length}')
			div.tab(each='{d,i in editSong.diffs}' class='diff_{d.diff}' data-index='{i}' onclick='{ showEditFormDiff.bind(this, editSong, d, i) }' ) {d.diff}
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
		
	footer 
	
	// ---------------------------
	// Style
	style(type="scss").
		@import "../css/main.scss"
		
	// ---------------------------
	// Script
	script.
		var $ = require("jquery");
		
		// re-lendering
		var lenderingUpdate = (savedData, sortType) => {
			var allSongNameList = global.allSongList
				.filter(e => e.difficult === "Expert")
				.map((e,i) => {
					return {
						name: e.name,
						type: e.type,
						explevel: e.level,
						index: i,
						diffs: global.allSongList
							.filter(e_ => e_.name === e.name)
							.map(e_ => {
								var ssd = findSaveDataItem(savedData, e_.name, e_.difficult);
								return {
									diff: e_.difficult,
									totalnotes: e_.totalnotes,
									clearState: ssd.clearState || 0,
								};
							})
					} 
				});
			if(sortType == 1){
				allSongNameList.sort((a,b) => {
					if(a.explevel < b.explevel) return 1;
					if(a.explevel > b.explevel) return -1;
					if(a.index > b.index) return 1;
					if(a.index < b.index) return -1;
				})
			}
			this.allSongNameList = global.allSongNameList = allSongNameList;
		}
		
		// on Loading Action
		{
			// songlist get
			global.allSongList = require("../data/songdata.json");
			var savedData = getSaveData();
			
			// Update
			lenderingUpdate(savedData);
		}
		
		// 
		showEditForm(song) {
			$(`.song`).removeClass("active");
			$(`.song[data-index=${song.index}]`).addClass("active");
			this.editSong = song;
			this.editSongDiff = undefined;
		}
		
		// show edit
		showEditFormDiff(song, diff, i) {
			$(`.tab`).removeClass("active");
			$(`.tab[data-index=${i}]`).addClass("active");
			// load savedata
			var sd = getSaveData();
			var ssd = findSaveDataItem(sd, song.name, diff.diff);
			var totalnotes = song.diffs.find(e => e.diff === diff.diff).totalnotes;
			var df = {
				diff: diff.diff,
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
			this.editSongDiff = df;
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
			var simpleAliveCount = (bd * 50 + ms * 100 <= 1000);
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
			console.log(si);
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
			global.sortType = type;
			lenderingUpdate(savedData, type);
		}
		
		
		// get localstrage saved score
		function getSaveData() {
			// localstrage data get
			var lst = localStorage.getItem("savedScore");
			console.log(lst);
			return JSON.parse(lst || "[]");
		}
		function setSaveData(sd){
			// localstrage data get
			localStorage.setItem("savedScore", JSON.stringify(sd));
		}
		
		function setSaveItem(si, songName, songDiff){
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

		
		
		
		