import QtQuick

/*!
   \qmltype LoadingSkeletonGroup
   \inherits Item
   \inqmlmodule StatusQ.Components
   \since StatusQ.Components 0.1
   \brief Marks the area a shimmer sweep runs across for the LoadingSkeletonTile
   shapes inside it.

   It draws nothing itself: each tile finds its nearest LoadingSkeletonGroup
   ancestor and sweeps across the group's rectangle, so the shimmer runs over
   the whole arrangement as one band. Use this for creation-time skeleton
   screens instead of many LoadingComponent instances.

   Example:

   \qml
    LoadingSkeletonGroup {
        width: 200
        height: 60

        Row {
            spacing: 8
            LoadingSkeletonTile { width: 40; height: 40; radius: 20 }
            Column {
                spacing: 6
                LoadingSkeletonTile { width: 120; height: 14 }
                LoadingSkeletonTile { width: 80; height: 12 }
            }
        }
    }
   \endqml
*/
Item {}
