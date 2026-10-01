/// App-owned source identity only. These values do not authorize lesson media.
abstract final class JabLabSourceProjectionPin {
  static const appId = 'jablab';
  static const coursePath = 'assets/content/solo_boxing_course.v1.json';
  static const slicePath = 'assets/motion_content/jablab.source-slice.v1.json';
  static const projectionPath =
      'assets/motion_content/jablab.source-projection.v1.json';
  static const qaFixturePath = 'test/fixtures/jablab_v2k_source_pins_v1.json';

  static const courseSha256 =
      '0909b6c991fb631faeb357026475f787ae226562e261a479e0eb315095de069f';
  static const sliceSha256 =
      '2dcc939cddf1b4a31dd3322bfd19bb9cf3ed32463e33f1d5e0c70ebd1fc8bc91';
  static const projectionSha256 =
      '24d4ef12ea037f06a7aeee9ca100128caafc93a2e419ebf3536e6a63f5fc5559';
  static const qaFixtureSha256 =
      'da806a35f838e8dbe6e770b0d8168bd99214f62eee5833dcfd584ee9cc035241';
  static const sourceCatalogSha256 =
      '791bfea8e1479307794bcf8799cf703a7a840bcd3058c1a0d7fdf065d32d8594';
  // This is the v2k preproduction source manifest, not a signed release root.
  static const sourceManifestSha256 =
      'd887683c9a9b9bdb8d4ab7c51cdc5a5b4b4de6a918079e4cfd9cf543e9751e60';
  static const sourceProofSha256 =
      'dec615e14881b86b7676e1157f63b8bf6269026d856e59f2ee3a65d7f97e512a';

  static const lessonCount = 39;
  static const sceneCount = 292;
  static const variantCount = 292;
  static const heldCount = 0;
}
