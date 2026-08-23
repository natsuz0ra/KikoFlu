import { uiMaterial } from '@kit.ArkUI';

export function immersiveMaterial(): uiMaterial.ImmersiveMaterial {
  return new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    interactive: true,
    lightEffect: {}
  });
}

export function topIconResource(icon: string): Resource {
  switch (icon) {
    case 'arrow_back':
      return $r('app.media.top_arrow_back');
    case 'arrow_drop_down':
      return $r('app.media.top_arrow_drop_down');
    case 'grid_3x3':
      return $r('app.media.top_grid_3x3');
    case 'view_list':
      return $r('app.media.top_view_list');
    case 'view_agenda':
      return $r('app.media.top_view_agenda');
    case 'closed_caption':
      return $r('app.media.top_closed_caption');
    case 'closed_caption_disabled':
      return $r('app.media.top_closed_caption_disabled');
    case 'sort':
      return $r('app.media.top_sort');
    case 'filter_alt':
      return $r('app.media.top_filter_alt');
    case 'filter_alt_outlined':
      return $r('app.media.top_filter_alt_outlined');
    case 'local_fire':
      return $r('app.media.top_local_fire');
    case 'auto_awesome':
      return $r('app.media.top_auto_awesome');
    case 'bookmark':
      return $r('app.media.top_bookmark');
    case 'history':
      return $r('app.media.top_history');
    case 'playlist_play':
      return $r('app.media.top_playlist_play');
    case 'download':
      return $r('app.media.top_download');
    case 'subtitles':
      return $r('app.media.top_subtitles');
    case 'all_inclusive':
      return $r('app.media.top_all_inclusive');
    case 'headphones':
      return $r('app.media.top_headphones');
    case 'check_circle':
      return $r('app.media.top_check_circle');
    case 'replay':
      return $r('app.media.top_replay');
    case 'schedule':
      return $r('app.media.top_schedule');
    default:
      return $r('app.media.top_grid_view');
  }
}
