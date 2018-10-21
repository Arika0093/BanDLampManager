main
	header
	div.sortButtons
		span(class='{ active: sortType == 0 }' onclick='{ sortClick.bind(this, 0) }') ▼標準
		span(class='{ active: sortType == 1 }' onclick='{ sortClick.bind(this, 1) }') ▼レベル順
		span(class='{ active: sortType == 4 }' onclick='{ sortClick.bind(this, 4) }') ▼クリア状況順
		span(class='{ active: sortType == 2 }' onclick='{ sortClick.bind(this, 2) }') ▼Gr数順
		span(class='{ active: sortType == 3 }' onclick='{ sortClick.bind(this, 3) }') ▼Notes数順
		select#targetDifficults(onchange='{ sortClick }')
			option(data-index=0, value="Easy") Easy
			option(data-index=1, value="Normal") Normal
			option(data-index=2, value="Hard") Hard
			option(data-index=3, value="Expert" selected=true) Expert
			option(data-index=4, value="Special") Special
		input#viewOnlyMode(type="checkbox" onclick='{ toggleViewOnlyMode }')
		label(for="viewOnlyMode") 閲覧用モード

	div.songLists(class='{wideView: viewOnly}')
		div.song(each='{s in allSongNameList}' class='type_{s.type}' data-disp='{s.dispValue}' data-index='{s.index}' onclick='{ showEditForm.bind(this, s) }')
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
						index: i,
						diffs: global.allSongList
							.filter(e_ => e_.name === e.name)
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
				if(!sortType){ e.dispValue = e.index + 1 }
				if(sortType == 1){ e.dispValue = e.seldiff.explevel }
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
				if(sortType == 3){ e.dispValue = e.seldiff.totalnotes }
				if(sortType == 4) {
					var d = ["NC", "CL", "FC", "AP"];
					e.dispValue = d[e.seldiff.clearState || 0];
				}
			});
			
			if(sortType >= 1){
				allSongNameList.sort((a,b) => {
					if(sortType == 1){
						// 降順
						if (a.seldiff.explevel < b.seldiff.explevel) return +1;
						if (a.seldiff.explevel > b.seldiff.explevel) return -1;
					}
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
				var selectedIndex = seled.data("index") || 3;
				this.activeTabIndex = selectedIndex;
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
			if(type >= 0){
				this.sortType = global.sortType = type;
			}
			lenderingUpdate(savedData, global.sortType);
		}
		
		toggleViewOnlyMode() {
			if(this.viewOnly = $("#viewOnlyMode").prop("checked")){
				this.editSong = null;
				this.editSongDiff = null;
			}
		}
		
		// get localstrage saved score
		function getSaveData() {
			// localstrage data get
			var lst = localStorage.getItem("savedScore");
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

		
		
		